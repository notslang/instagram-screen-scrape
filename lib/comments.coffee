{jsonRequest} = require './util'
{urlSegmentToInstagramId} = require 'instagram-id-to-url-segment'
Readable = require 'readable-stream/readable'
request = require 'request'

###*
 * Stream that scrapes as many comments as possible for a given user.
 * @param {String} options.username
 * @return {Stream} A stream of comment objects.
###
class InstagramComments extends Readable
  _lock: false
  _minId: undefined
  _csrfToken: undefined

  constructor: ({@post}) ->
    @cookieJar = request.jar()
    @postId = urlSegmentToInstagramId(@post)
    # remove the explicit HWM setting when github.com/nodejs/node/commit/e1fec22
    # is merged into readable-stream
    super(highWaterMark: 16, objectMode: true)
    @_readableState.destroyed = false

  ###*
   * Make a request for a Instagram page, parse the response, and get all the
     comments.
   * @param {String} username
   * @param {String} [startingId] The maximum comment id query for (the lowest
     one from the last request), or undefined if this is the first request.
   * @return {Stream} A stream of comments
   * @private
  ###
  _getCommentsPage: (minId) =>
    # this is actually only needed on the 2nd request, once we have a cookie for
    # the csrf token, but don't have it stored in `@_csrfToken` yet
    if not @_csrfToken?
      for cookie in @cookieJar.getCookies 'https://instagram.com'
        if cookie.key is 'csrftoken'
          @_csrfToken = cookie.value
          break

    if not @_csrfToken?
      # this is both to get the csrf token, and get the first few comments. it's
      # also nice that this is exactly how instagram does it on their website,
      # so it should look like normal traffic
      jsonRequest('media.comments.nodes.*'
        uri: "https://instagram.com/p/#{@post}/?__a=1"
        jar: @cookieJar
      )
    else if minId?
      # note: you can actually get all the comments on the post if you just
      # remove `.before(#{minId}, 4200)`, but we can't do any sort of pagination
      # so we end up with a huge and long request if we do it that way. also,
      # nothing on the Instagram website actually uses that, so it might go away
      query = """
        ig_media(#{@postId}) {
          comments.before(#{minId}, 20) {
            nodes {
              id,
              created_at,
              text,
              user {
                id,
                profile_pic_url,
                username
              }
            },
            page_info
          }
        }
      """.replace(/\s/g, '')

      jsonRequest('.nodes.*'
        method: 'POST'
        url: 'https://instagram.com/query/'
        jar: @cookieJar # the CSRF token needs to be passed as a cookie too
        form:
          q: query
          ref: 'media::show'
        headers:
          'X-CSRFToken': @_csrfToken
          'Referer': 'https://instagram.com/'
      )
    else
      @emit('error', 'Had csrfToken but no minId for post query.')

  _read: =>
    # prevent additional requests from being made while one is already running
    if @_lock then return
    @_lock = true

    if @_readableState.destroyed
      @push(null)
      return

    commentsReturned = 0
    hasMoreComments = false

    # we hold one comment in a buffer because we need something to send directly
    # after we turn off the lock
    lastComment = undefined

    @_getCommentsPage(@_minId).on('error', (err) =>
      @emit('error', err)
    ).on('data', (rawComment) =>
      commentsReturned += 1

      # if the request returned enough comments to hit the limit, then we assume
      # there are more. It could be that there are exactly 20 comments, but this
      # is so unlikely that it's cheaper to not bother with checking the
      # `page_info` in the response
      if commentsReturned >= 20 then hasMoreComments = true

      comment =
        id: rawComment.id
        username: rawComment.user.username
        time: rawComment['created_at']
        text: rawComment.text

      if commentsReturned is 1
        @_minId = rawComment.id # only the first one really matters

      if lastComment? then @push(lastComment)
      lastComment = comment
    ).on('end', =>
      if hasMoreComments then @_lock = false
      if lastComment? then @push(lastComment)
      if not hasMoreComments then @push(null)
    )

  destroy: =>
    if @_readableState.destroyed then return
    @_readableState.destroyed = true

    @_destroy((err) =>
      if (err) then @emit('error', err)
      @emit('close')
    )

  _destroy: (cb) ->
    process.nextTick(cb)

module.exports = InstagramComments

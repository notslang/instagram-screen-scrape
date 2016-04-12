# see http://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html for
# why we use readable-stream
Readable = require 'readable-stream/readable'
{jsonRequest} = require './util'

###*
 * Make a request for a Instagram page, parse the response, and get all the
   posts.
 * @param {String} username
 * @param {String} [startingId] The maximum post id query for (the lowest one
   from the last request), or undefined if this is the first request.
 * @return {Stream} A stream of posts
###
getPosts = (username, startingId) ->
  jsonRequest('items.*'
    uri: "https://instagram.com/#{username}/media/"
    qs:
      'max_id': startingId
  )

###*
 * Stream that scrapes as many posts as possible for a given user.
 * @param {String} options.username
 * @return {Stream} A stream of post objects.
###
class InstagramPosts extends Readable
  _lock: false
  _minPostId: undefined

  constructor: ({@username}) ->
    # remove the explicit HWM setting when github.com/nodejs/node/commit/e1fec22
    # is merged into readable-stream
    super(highWaterMark: 16, objectMode: true)
    @_readableState.destroyed = false

  _read: =>
    # prevent additional requests from being made while one is already running
    if @_lock then return
    @_lock = true

    if @_readableState.destroyed
      @push(null)
      return

    hasMorePosts = false

    # we hold one post in a buffer because we need something to send directly
    # after we turn off the lock
    lastPost = undefined

    getPosts(@username, @_minPostId).on('error', (err) =>
      @emit('error', err)
    ).on('data', (rawPost) =>
      # if the request returned some posts, then we assume there are more
      hasMorePosts = true

      post =
        id: rawPost.id
        username: @username
        time: +rawPost['created_time']
        type: rawPost.type
        likes: rawPost.likes.count
        comments: rawPost.comments.count

      if rawPost.caption?
        post.text = rawPost.caption.text

      switch post.type
        when 'image'
          post.media = rawPost.images['standard_resolution'].url
        when 'video'
          post.media = rawPost.videos['standard_resolution'].url
        else
          throw new Error("Instagram did not return a URL for the media on post
          #{post.id}")

      @_minPostId = rawPost.id # only the last one really matters

      if lastPost? then @push(lastPost)
      lastPost = post
    ).on('end', =>
      if hasMorePosts then @_lock = false
      if lastPost? then @push(lastPost)
      if not hasMorePosts then @push(null)
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

module.exports = InstagramPosts

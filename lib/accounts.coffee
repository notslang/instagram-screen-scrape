# see http://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html for
# why we use readable-stream
Readable = require 'readable-stream/readable'
{jsonRequest} = require './util'

###*
 * Make a request for a Instagram page, parse the response, and get all the
   posts.
 * @param {String} query
 * @return {Stream} A stream of profile data
###
getUsers = (query) ->
  jsonRequest('users.*'
    uri: "https://www.instagram.com/web/search/topsearch/?context=blended&query=#{query}"
  )

###*
 * Stream that scrapes as many posts as possible for a given user.
 * @param {String} options.query
 * @param {String} options.limit max amount of results to grab (optional and not working atm)
 * @return {Stream} A stream of post objects.
###
class InstagramAccounts extends Readable
  _lock: false
  # _minPostId: undefined

  constructor: ({@query,@limit}) ->
    # remove the explicit HWM setting when github.com/nodejs/node/commit/e1fec22
    # is merged into readable-stream

    super(highWaterMark: 16, objectMode: true)
    @_readableState.destroyed = false
    # console.log 'limit', {@limit}
    # @limit = @limit || 10

  _read: =>
    # prevent additional requests from being made while one is already running
    if @_lock then return
    @_lock = true

    if @_readableState.destroyed
      @push(null)
      return

    # hasMoreUsers = false
    foundAccounts = 0

    # we hold one post in a buffer because we need something to send directly
    # after we turn off the lock
    lastAccount = undefined

    getUsers(@query).on('error', (err) =>
      @emit('error', err)
    ).on('data', (raw) =>
      # if the request returned some profiles, be happy and stop searching
      hasMoreUsers = true

      if foundAccounts >= @limit
        hasMoreUsers = false
        # console.log 'foundAccounts', foundAccounts, @limit
        @destroy()

      account =
        user_id: raw.user.pk
        username: raw.user.username
        profile_picture: raw.user.profile_pic_url
        full_name: raw.user.full_name
        follower_count: raw.user.follower_count
        is_private: raw.user.is_private
        is_verified: raw.user.is_verified

      ++foundAccounts

      # @_minPostId = raw.id # only the last one really matters

      if lastAccount? then @push(lastAccount)
      lastAccount = account
    ).on('end', =>
      if foundAccounts < @limit then @_lock = false
      if lastAccount? then @push(lastAccount)
      if not foundAccounts >= @limit then @push(null)
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

module.exports = InstagramAccounts

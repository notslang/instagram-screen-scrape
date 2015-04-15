# see http://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html for
# why we use readable-stream
Readable = require('readable-stream').Readable
request = require 'request'
JSONStream = require 'JSONStream'
H = require 'highland'
W = require 'when'

###*
 * Make a request for a Instagram page, parse the response, and get all the
   posts.
 * @param {String} username
 * @param {String} [startingId] The maximum post id query for (the lowest one
   from the last request), or undefined if this is the first request.
 * @return {Array} A stream of posts
###
getPostPage = (username, startingId) ->
  request.get(
    uri: "https://instagram.com/#{username}/media/"
    qs:
      'max_id': startingId
  ).on('error', (err) ->
    console.error err # TODO: fix
  ).pipe(
    JSONStream.parse('items.*')
  )

###*
 * Scrape as many posts as possible for a given user.
 * @param {String} options.username
 * @return {Stream} A stream of post objects.
###
module.exports = ({username}) ->
  output = new Readable(objectMode: true)
  output._read = (->) # prevent "Error: not implemented" with a noop

  scrape = (username, startingId) ->
    W.promise((resolve, reject) ->
      minId = null

      H(
        getPostPage(username, startingId)
      ).map((rawPost) ->
        post =
          id: rawPost.code
          username: username
          time: +rawPost['created_time']
          type: rawPost.type
          like: rawPost.likes.count
          comment: rawPost.comments.count

        if rawPost.caption?
          post.text = rawPost.caption.text

        if rawPost.images?
          post.image = rawPost.images['standard_resolution'].url

        if rawPost.videos?
          post.video = rawPost.videos['standard_resolution'].url

        minId = rawPost.id # last id so far
        output.push(post)
      ).on('error', (err) ->
        reject(err)
      ).on('end', ->
        resolve(minId)
      ).toArray( ->) # hack to make the stream flow
    ).then((minId) ->
      if minId?
        return scrape(username, minId)
      else
        output.push(null)
        return
    )

  scrape(username)
  return output

{validate} = require 'json-schema'
isStream = require 'isstream'
should = require 'should'

{InstagramPosts, InstagramComments} = require '../lib'
postSchema = require '../lib/post.schema'
commentSchema = require '../lib/comment.schema'

describe 'post stream', ->
  before ->
    @stream = new InstagramPosts(username: 'slang800')
    @posts = []

  it 'should return a stream', ->
    isStream(@stream).should.be.true

  it 'should stream post objects', (done) ->
    @timeout(4000)
    @stream.on('data', (post) =>
      validate(post, postSchema).errors.should.eql([])
      @posts.push post
    ).on('end', =>
      @posts.length.should.be.above(0)
      done()
    )

  it 'should include a valid time for each post', ->
    # unix time values
    year2000 = 946702800
    year3000 = 32503698000

    for post in @posts
      (post.time > year2000).should.be.true
      (post.time < year3000).should.be.true # instagram should be dead by then

describe 'comment stream', ->
  before ->
    @stream = new InstagramComments(post: '5n7dDmhTr3')
    @comments = []

  it 'should return a stream', ->
    isStream(@stream).should.be.true

  it 'should stream comment objects', (done) ->
    @timeout(4000)
    @stream.on('data', (comment) =>
      validate(comment, commentSchema).errors.should.eql([])
      @comments.push comment
    ).on('end', =>
      @comments.length.should.be.above(0)
      done()
    )

  it 'should include a valid time for each comment', ->
    # unix time values
    year2000 = 946702800
    year3000 = 32503698000

    for comment in @comments
      (comment.time > year2000).should.be.true
      (comment.time < year3000).should.be.true

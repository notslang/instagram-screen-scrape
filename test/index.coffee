should = require 'should'
isStream = require 'isstream'

scrape = require '../lib'

describe 'post stream', ->
  before ->
    @stream = scrape(username: 'slang800')
    @posts = []

  it 'should return a stream', ->
    isStream(@stream).should.be.true

  it 'should stream post objects', (done) ->
    @timeout(4000)
    @stream.on('readable', =>
      post = @stream.read()
      post.should.be.an.instanceOf(Object)
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
      post.time.should.be.an.instanceOf(Number)
      (post.time > year2000).should.be.true
      (post.time < year3000).should.be.true # twitter should be dead by then

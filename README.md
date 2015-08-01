# Instagram Screen Scrape
[![Build Status](http://img.shields.io/travis/slang800/instagram-screen-scrape.svg?style=flat-square)](https://travis-ci.org/slang800/instagram-screen-scrape) [![NPM version](http://img.shields.io/npm/v/instagram-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/instagram-screen-scrape) [![NPM license](http://img.shields.io/npm/l/instagram-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/instagram-screen-scrape)

A tool for scraping public data from Instagram, without needing to get permission from Instagram. It can (theoretically) scrape anything that a non-logged-in user can see. But, right now it only supports getting posts for a given username or comments for a given post.

## Example
### CLI
The CLI operates entirely over STDOUT, and will output posts as it scrapes them. The following example is truncated because the output of the real command is obviously very long... it will end with a closing bracket (making it valid JSON) if you see the full output.

```bash
$ instagram-screen-scrape posts --username carrotcreative
[{"id":"0toxcII4Eo","username":"carrotcreative","time":1427420497,"type":"image","likes":82,"comments":3,"text":"Our CTO, @kylemac, speaking on the #LetsTalkCulture panel tonight @paperlesspost.","media":"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/11055816_398297847022038_803876945_n.jpg"},
{"id":"0qPcnuI4Pr","username":"carrotcreative","time":1427306556,"type":"image","likes":80,"comments":4,"text":"#bitchesbebakin took it to another level today for @nporteschaikin and @slang800's #Carrotversaries today.","media":"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/10959049_1546104325652055_1320782099_n.jpg"},
{"id":"0WLnjlo4Ft","username":"carrotcreative","time":1426633460,"type":"image","likes":61,"comments":1,"text":"T-shirts speak louder than words. Come find us @sxsw.","media":"https://scontent.cdninstagram.com/hphotos-xfa1/t51.2885-15/e15/11032904_789885121108568_378908081_n.jpg"},
```

We can also scrape comments:

```bash
$ instagram-screen-scrape comments --post 0qPcnuI4Pr
[{"id":"948651188581269518","username":"johnlustina","time":1427308055,"text":"@margeauxlustina"},
{"id":"948682633420963943","username":"rita_xo","time":1427311804,"text":"👌@emilykalen"},
{"id":"948734454231433861","username":"david_berkhin","time":1427317981,"text":"looks so good!"},
{"id":"948824521079751272","username":"k.kate","time":1427328718,"text":"Macarons or a Petri dish full of cells? ¯\\_(ツ)_/¯"}]
```

By default, there is 1 line per post, making it easy to pipe into other tools. The following example uses `wc -l` to count how many posts are returned. As you can see, I don't post much.

```bash
$ instagram-screen-scrape posts -u slang800 | wc -l
2
```

### JavaScript Module
The following example is in CoffeeScript.

```coffee
{InstagramPosts} = require 'instagram-screen-scrape'

# create the stream
streamOfPosts = new InstagramPosts(username: 'slang800')

# do something interesting with the stream
streamOfPosts.on('data', (post) ->
  # since it's an object-mode stream, we get objects from it and don't need to
  # parse JSON or anything

  # the time field is represented in UNIX time
  time = new Date(post.time * 1000)

  # output something like "slang800's post from 4/5/2015 got 1 like(s), and 0
  # comment(s)"
  console.log "slang800's post from #{time.toLocaleDateString()} got
  #{post.likes} like(s), and #{post.comments} comment(s)"
)
```

The following example is the same as the last one, but in JavaScript.

```js
var InstagramPosts, streamOfPosts;
InstagramPosts = require('instagram-screen-scrape').InstagramPosts;

streamOfPosts = new InstagramPosts({
  username: 'slang800'
});

streamOfPosts.on('data', function(post) {
  var time = new Date(post.time * 1000);
  console.log([
    "slang800's post from ",
    time.toLocaleDateString(),
    " got ",
    post.likes,
    " like(s), and ",
    post.comments,
    " comment(s)"
  ].join(''));
});
```

And we can scrape comments in a similar manner (shown in CoffeeScript):

```coffee
{InstagramComments} = require 'instagram-screen-scrape'

streamOfComments = new InstagramComments(post: '0qPcnuI4Pr')

# do something interesting with the stream
streamOfComments.on('data', (comment) ->
  # the time field is represented in UNIX time
  time = new Date(comment.time * 1000)

  console.log "#{comment.username} commented on #{time.toLocaleDateString()}:
  #{comment.text}"
)
```

## Why?
The fact that Instagram requires an app to be registered just to access the data that is publicly available on their site is excessively controlling. Scripts should be able to consume the same data as people, and with the same level of authentication. Sadly, Instagram doesn't provide an open, structured, and machine readable API.

So, we're forced to use a method that Instagram cannot effectively shut down without harming themselves: scraping their user-facing site.

## Caveats
- This is probably against the Instagram TOS, so don't use it if that sort of thing worries you.
- Whenever Instagram updates certain parts of their front-end this scraper will need to be updated to support the new markup.
- You can't scrape protected accounts or get engagement rates / impression counts (cause it's not public duh).

# Instagram Screen Scrape
[![Build Status](http://img.shields.io/travis/slang800/instagram-screen-scrape.svg?style=flat-square)](https://travis-ci.org/slang800/instagram-screen-scrape) [![NPM version](http://img.shields.io/npm/v/instagram-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/instagram-screen-scrape) [![NPM license](http://img.shields.io/npm/l/instagram-screen-scrape.svg?style=flat-square)](https://www.npmjs.org/package/instagram-screen-scrape)

A tool for scraping public data from Instagram, without needing to get permission from Instagram. It can (theoretically) scrape anything that a non-logged-in user can see. But, right now it only supports getting posts for a given username.

## Example
### CLI
The CLI operates entirely over STDOUT, and will output posts as it scrapes them. The following example is truncated because the output of the real command is obviously very long... it will end with a closing bracket (making it valid JSON) if you see the full output.

```bash
$ instagram-screen-scrape --username carrotcreative
[{"id":"0toxcII4Eo","username":"carrotcreative","time":1427420497,"type":"image","like":82,"comment":3,"text":"Our CTO, @kylemac, speaking on the #LetsTalkCulture panel tonight @paperlesspost.","image":"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/11055816_398297847022038_803876945_n.jpg"},
{"id":"0qPcnuI4Pr","username":"carrotcreative","time":1427306556,"type":"image","like":80,"comment":4,"text":"#bitchesbebakin took it to another level today for @nporteschaikin and @slang800's #Carrotversaries today.","image":"https://scontent.cdninstagram.com/hphotos-xaf1/t51.2885-15/e15/10959049_1546104325652055_1320782099_n.jpg"},
{"id":"0WLnjlo4Ft","username":"carrotcreative","time":1426633460,"type":"image","like":61,"comment":1,"text":"T-shirts speak louder than words. Come find us @sxsw.","image":"https://scontent.cdninstagram.com/hphotos-xfa1/t51.2885-15/e15/11032904_789885121108568_378908081_n.jpg"},
```

By default, there is 1 line per post, making it easy to pipe into other tools. The following example uses `wc -l` to count how many posts are returned. As you can see, I don't post much.

```bash
$ instagram-screen-scrape -u slang800 | wc -l
2
```

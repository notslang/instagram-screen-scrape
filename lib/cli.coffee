InstagramPosts = require './posts'
InstagramComments = require './comments'
packageInfo = require '../package'
ArgumentParser = require('argparse').ArgumentParser
JSONStream = require 'JSONStream'

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
subparser = argparser.addSubparsers(dest: 'subcommand')

subcommand = subparser.addParser(
  'comments'
  description: 'Scrape comments for a given post'
  addHelp: true
)
subcommand.addArgument(
  ['-p', '--post']
  type: 'string'
  help: 'Alphanumeric post id to scrape. This is unique across all of Instagram
  (so the username does not need to be specified when this option is used), and
  the id can be gotten from Instagram URLs with the format
  `instagram.com/p/<post id>`.'
)

subcommand = subparser.addParser(
  'posts'
  description: 'Scrape posts by username or post id'
  addHelp: true
)
subcommand.addArgument(
  ['-u', '--username']
  type: 'string'
  help: 'Username of the account to scrape.'
)

argv = argparser.parseArgs()
{subcommand} = argv
delete argv.subcommand

(
  if subcommand is 'posts'
    new InstagramPosts(argv)
  else # comments
    new InstagramComments(argv)
).pipe(
  JSONStream.stringify('[', ',\n', ']\n')
).pipe(
  process.stdout
)

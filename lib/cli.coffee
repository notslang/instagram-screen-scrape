scrape = require './'
packageInfo = require '../package'
ArgumentParser = require('argparse').ArgumentParser
JSONStream = require 'JSONStream'

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--username', '-u']
  type: 'string'
  help: 'Username of the account to scrape'
  required: true
)

argv = argparser.parseArgs()
scrape(argv).pipe(JSONStream.stringify('[', ',\n', ']\n')).pipe(process.stdout)

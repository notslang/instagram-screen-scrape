request = require 'request'
JSONStream = require 'JSONStream'
zlib = require 'zlib'

jsonRequest = (jsonSelector, options) ->
  outStream = JSONStream.parse(jsonSelector)
  options.gzip = true
  request(
    options
  ).on('response', (response) ->
    if response.statusCode is 200
      encoding = response.headers['content-encoding']?.trim().toLowerCase()
      if encoding is 'gzip'
        gunzip = zlib.createGunzip()
        response.pipe(gunzip).pipe(outStream)
      else
        response.pipe(outStream)
    else
      throw new Error("Instagram returned status code: #{response.statusCode}")
  )
  return outStream

module.exports = {jsonRequest}

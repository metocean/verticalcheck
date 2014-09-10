fs = require 'fs'
http = require 'http'

files = []
route = (url, contentType, content) ->
	files.push u: url, t: contentType, c: content

route '/', 'text/html', 'index.html'
route '/favicon.ico', 'image/x-icon', 'favicon.ico'
route '/style.css', 'text/css', 'style.css'
route '/script.js', 'application/javascript', 'script.js'

CSON = require 'cson'
config = CSON.parseFileSync 'verticalcheck.cson'

api = [
	check: 'dns'
	isUp: yes
	param: 'google.co.nz'
	message: 'dns entry google.co.nz resolves to 16 known ip addresses'
]

results = null
calculatedTime = 0
result = (task, check, isUp, param, message) ->
  results.push name: task.name, check: check, isUp: isUp, param: param, message: message
verticalcheck = (cb) ->
	currentTime = new Date().getTime()
	return cb() if currentTime < calculatedTime + 5 * 60 * 1000
	
	calculatedTime = currentTime
	results = []
	require('./library') config, result, cb

route '/api', (req, res) ->
	verticalcheck ->
		res.writeHead 200, 'Content-Type': 'application/json'
		res.end JSON.stringify results

server = http.createServer (req, res) ->
	for file in files
		if file.u is req.url
			return file.t req, res if typeof file.t is 'function'
			res.writeHead 200, 'Content-Type': file.t
			res.end fs.readFileSync file.c
			return
	
	res.writeHead 404, 'Content-Type': 'text/plain'
	res.end '404 - Goneburgers'

server.listen 1234

console.log 'Home grown http server running on port 1234'
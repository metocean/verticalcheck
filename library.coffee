dns = require 'dns'
ping = require 'ping'
parseurl = require('url').parse
webget =
	'http:': require('http').get
	'https:': require('https').get

series = (tasks, callback) ->
	tasks = tasks.slice 0
	next = (cb) ->
		return cb() if tasks.length is 0
		task = tasks.shift()
		task -> next cb
	result = (cb) -> next cb
	result(callback) if callback?
	result

parallel = (tasks, callback) ->
	count = tasks.length
	result = (cb) ->
		return cb() if count is 0
		for task in tasks
			task ->
				count--
				cb() if count is 0
	result(callback) if callback?
	result
	
checks =
	dns: (task, result, cb) ->
		tasks = []
		for host, ip of task.dns
			do (host, ip) ->
				tasks.push (cb) ->
					dns.resolve4 host, (err, addresses) ->
						if err?
							result task, 'dns', no, host, "#{host} → ??? #{err}", "There was an error looking up the DNS address. Either the address does not resolve to an IP address or this server is having DNS or connectivity issues. Have a look at the DNS server to see if it is correctly configured and have a look at this server's network to see if it is working correctly."
							return cb()
						
						if addresses.length is 1 and addresses[0] is ip
							result task, 'dns', yes, host, "#{host} → #{ip}", "The DNS address correctly resolved."
							return cb()
						
						if Object.prototype.toString.call(ip) is '[object Array]' and addresses.length is ip.length
							skip = no
							for a in addresses
								unless a in ip
									skip = yes
									break
							unless skip
								result 'dns', yes, host, "#{host} → #{ip.length} ip addresses", "The DNS address correctly resolved to multiple IP addresses."
								return cb()
						
						result task, 'dns', no, host, "#{host} → #{addresses} instead of #{ip}", "The DNS address resolved to an unexpected address. The address may have been intentionally changed or we may be experiencing DNS issues. Have a look at the DNS server to see if it is correctly configured."
						cb()
					
		parallel tasks, cb
	
	ping: (task, result, cb) ->
		tasks = task.ping.map (host) -> (callback) ->
			ping.sys.probe host, (isAlive) ->
				if !isAlive
					result task, 'ping', no, host, "#{host} is down", "The specified host did not respond to ping. This could because this server was not able to contact that IP address due to connectivity issues, or the host has been configured not to respond to ping, or the host is currently not running. Check to see if the host server is running."
				else
					result task, 'ping', yes, host, "#{host} is up", "The host responded to ping."
				callback()
		parallel tasks, cb
	
	http: (task, result, cb) ->
		tasks = task.http.map (url) -> (callback) ->
			code = 200
			if typeof url is 'object'
				for key, value of url
					href = key
					code = value
				url = href
			
			chunks = parseurl url
			options =
				hostname: chunks.hostname
				port: chunks.port
				path: chunks.path
				agent: no
			port = chunks.port
			if !options.port?
				options.port = 443 if chunks.protocol is 'https:'
				options.port = 80 if chunks.protocol is 'http:'
			
			hasReturned = no
			req = webget[chunks.protocol](options, (res) ->
				return if hasReturned
				if res.statusCode is code
					result task, 'http', yes, url, "#{url} responded", "The specified url responded to an http request."
				else
					result task, 'http', no, url, "#{url} expected #{code} received #{res.statusCode} instead", "The url was requested successfully however the status code this server received was not expected. Normal content has a status code of 200. Status codes of 301 and 302 are redirects and are often used for login systems. Status codes of 400 means that the request this server made was bad. A status code of 403 means permission denied. 404 means not found and a status code of 500 means that there was an error on the server. If the status code returned is 500 the server needs to be looked at as the webserver is having an issue. Any other status codes are probably due to a configuration issue or this server is talking to the wrong server."
				hasReturned = yes
				callback()
			).on('error', (err) ->
				return if hasReturned
				result task, 'http', no, url, "#{url} #{err.message}", "An error occurred when attempting an http request. This is often a network issue. Look at the DNS for the destination server and this server's network connectivity."
				hasReturned = yes
				callback()
			)
			req.setTimeout 5000, ->
				return if hasReturned
				result task, 'http', no, url, "#{url} timed out after 5 seconds", "5 seconds has elapsed with no response from the destination server. This happens when the destination server is not running a webserver, the destination server currently not running or this server is having network problems. Check the IP address for the destination server and make sure it responds to ping then check to see if the webserver is running correctly on the destination server."
				hasReturned = yes
				callback()
		parallel tasks, cb

run = (task, result, cb) ->
	if Object.prototype.toString.call(task) is '[object Array]'
		tasks = task.map (t) -> (callback) -> run t, result, callback
		parallel tasks, cb
	else
		tasks = []
		for check, f of checks
			do (check, f) ->
				if task[check]?
					tasks.push (cb) -> f task, result, cb
		series tasks, cb

module.exports = run
dns = require 'dns'
ping = require 'ping'
parseurl = require('url').parse
httpget = require('http').get

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
							result task, 'dns', no, host, "#{host} → ???"
							return cb()
						
						if addresses.length is 1 and addresses[0] is ip
							result task, 'dns', yes, host, "#{host} → #{ip}"
							return cb()
						
						if Object.prototype.toString.call(ip) is '[object Array]' and addresses.length is ip.length
							skip = no
							for a in addresses
								unless a in ip
									skip = yes
									break
							unless skip
								result 'dns', yes, host, "#{host} → #{ip.length} ip addresses"
								return cb()
						
						result task, 'dns', no, host, "#{host} → #{addresses} instead of #{ip}"
						cb()
					
		parallel tasks, cb
	
	ping: (task, result, cb) ->
		tasks = task.ping.map (host) -> (callback) ->
			ping.sys.probe host, (isAlive) ->
				if !isAlive
					result task, 'ping', no, host, "#{host} is down"
				else
					result task, 'ping', yes, host, "#{host} is up"
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
			req = httpget(options, (res) ->
				return if hasReturned
				if res.statusCode is code
					result task, 'http', yes, url, "#{url} responded"
				else
					result task, 'http', no, url, "#{url} expected #{code} received #{res.statusCode} instead"
				hasReturned = yes
				callback()
			).on('error', (err) ->
				return if hasReturned
				result task, 'http', no, url, "#{url} #{err.message}"
				hasReturned = yes
				callback()
			)
			req.setTimeout 5000, ->
				return if hasReturned
				result task, 'http', no, url, "#{url} timed out after 5 seconds"
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
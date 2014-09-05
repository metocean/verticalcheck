require 'colors'
args = process.argv.slice 2

usage = """

      Usage: #{'verticalcheck'.cyan} [config]
      
      Default configuration is #{'verticalcheck.cson'.blue}
      
      File format:
      
      [
        {
          dns:
            'google.co.nz': '131.203.3.177'
          ping: [
            'google.co.nz'
          ]
          http: [
            'https://google.co.nz/': 200
          ]
        }
      ]
   
"""

isInteractive = yes
for arg, i in args
  if arg is '--json'
    isInteractive = no
    args.splice i
    break

if args.length > 1
    console.error usage
    process.exit 1
  
config = 'verticalcheck.cson'
if args.length is 1
  config = args[0]

fs = require 'fs'
if !fs.existsSync config
  console.error """
        
        Configuration not found at '#{config}'
        
  """
  process.exit 1

CSON = require 'cson'
config = CSON.parseFileSync config

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


dns = require 'dns'
ping = require 'ping'
parseurl = require('url').parse
httpget = require('http').get

waserror = no
results = []
result = (check, isUp, param, message) ->
  if !isInteractive
    return results.push
      check: check
      isUp: isUp
      param: param
      message: message
  
  return console.log " #{'√'.green} #{message.green}" if isUp
  
  waserror = yes
  console.error " #{'X'.red} #{message.red}"

checks =
  dns: (task, cb) ->
    tasks = []
    for host, ip of task.dns
      do (host, ip) ->
        tasks.push (cb) ->
          dns.resolve4 host, (err, addresses) ->
            if err?
              result 'dns', no, host, "unable to resolve dns for #{host}"
              return cb()
            
            if addresses.length is 1 and addresses[0] is ip
              result 'dns', yes, host, "dns entry #{host} resolves to #{ip}"
              return cb()
            
            if Object.prototype.toString.call(ip) is '[object Array]' and addresses.length is ip.length
              skip = no
              for a in addresses
                unless a in ip
                  skip = yes
                  break
              unless skip
                result 'dns', yes, host, "dns entry #{host} resolves to #{ip.length} known ip addresses"
                return cb()
            
            result 'dns', no, host, "dns entry #{host} resolved to #{addresses} instead of #{ip}"
            cb()
          
    parallel tasks, cb
  
  ping: (task, cb) ->
    tasks = task.ping.map (host) -> (callback) ->
      ping.sys.probe host, (isAlive) ->
        if !isAlive
          result 'ping', no, host, "ping #{host} is down"
        else
          result 'ping', yes, host, "ping #{host} is up"
        callback()
    parallel tasks, cb
  
  http: (task, cb) ->
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
      
      httpget(options, (res) ->
        if res.statusCode is code
          result 'http', yes, url, "http #{url} is web'd"
        else
          result 'http', no, url, "http expected #{code}from #{url} and received #{res.statusCode} instead"
        callback()
      ).on('error', (err) ->
        result 'http', no, url, "http tried to reach #{url} and received #{err.message} instead"
        callback()
      )
    parallel tasks, cb

run = (task, cb) ->
  if Object.prototype.toString.call(task) is '[object Array]'
    tasks = task.map (t) -> (callback) -> run t, callback
    parallel tasks, cb
  else
    tasks = []
    for check, f of checks
      do (check, f) ->
        if task[check]?
          tasks.push (cb) -> f task, cb
    series tasks, cb

if !isInteractive
  return run config, -> console.log results
  
console.log()
console.log "   #{'Vertical Check'.cyan} -- Are you up or down?"
console.log()

run config, ->
  if waserror
    console.error()
    console.error '   fin with errors.'.red
    console.error()
    process.exit 1
    
  console.log()
  console.log '   fin.'.green
  console.log()
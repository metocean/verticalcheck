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

waserror = no
results = []
result = (task, check, isUp, param, message) ->
  if !isInteractive
    return results.push
      name: task.name
      check: check
      isUp: isUp
      param: param
      message: message
  
  return console.log " #{'↑'.green} #{message.green}" if isUp
  
  waserror = yes
  console.error " #{'↓'.red} #{message.red}"

if !isInteractive
  return require('../library') config, result, -> console.log JSON.stringify results, null, 2
  
console.log()
console.log "   #{'Vertical Check'.cyan} -- Are you up or down?"
console.log()

require('../library') config, result, ->
  if waserror
    console.error()
    console.error '   fin with errors.'.red
    console.error()
    process.exit 1
    
  console.log()
  console.log '   fin.'.green
  console.log()
  
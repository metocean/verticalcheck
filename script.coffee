groupby = (array, accessor) ->
	map = {}
	for item in array
		key = accessor item
		map[key] = [] if !map[key]?
		map[key].push item
	result = []
	for key, items of map
		result.push key: key, items: items
	result

class ViewModel
	constructor: ->
		@results = ko.observableArray []
		@haserror = ko.observable no
		@autorefresh = yes
		@state = ko.observable 'counting down'
		@countdown = ko.observable null
		@state.subscribe (value) ->
			console.log value
		setInterval @tick, 1000
	
	query: =>
		$.get "api?v=#{new Date().getTime()}", (results) =>
			@results.removeAll()
			results = groupby results, (r) -> r.name
			for result in results
				@results.push
					key: result.key
					items: groupby result.items, (r) -> r.check
			@haserror no
			@check()
			for grouping in @results()
				for checktype in grouping.items
					for check in checktype.items
						if !check.isUp
							@haserror yes
	
	check: =>
		@countdown null
		@state 'idle'
		
		if @autorefresh
			@state 'counting down'
			@countdown 60
	
	tick: =>
		return if @state() isnt 'counting down'
		@countdown @countdown() - 1
		if @countdown() is 0
			@countdown null
			@state 'refreshing'
			@query()
	
	click: (check) =>
		alert "#{check.message}\n\n#{check.explanation}"
	
	refresh: =>
		@autorefresh = !@autorefresh
		@check()

$ ->
	vm = new ViewModel
	ko.applyBindings vm
	vm.query()
	
	
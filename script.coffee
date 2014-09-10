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
	
	query: =>
		$.get 'api', (results) =>
			@results.removeAll()
			results = groupby results, (r) -> r.name
			for result in results
				@results.push
					key: result.key
					items: groupby result.items, (r) -> r.check
	
	click: (check) =>
		alert check.message

$ ->
	vm = new ViewModel
	ko.applyBindings vm
	vm.query()
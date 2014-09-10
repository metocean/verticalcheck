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
	
	query: =>
		$.get 'api', (results) =>
			@results.removeAll()
			results = groupby results, (r) -> r.name
			for result in results
				@results.push
					key: result.key
					items: groupby result.items, (r) -> r.check
			@haserror no
			for grouping in @results()
				for checktype in grouping.items
					for check in checktype.items
						if !check.isUp
							@haserror yes
	
	click: (check) =>
		alert "#{check.message}\n\n#{check.explanation}"

$ ->
	vm = new ViewModel
	ko.applyBindings vm
	vm.query()
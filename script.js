// Generated by CoffeeScript 1.7.1
(function() {
  var ViewModel, groupby,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  groupby = function(array, accessor) {
    var item, items, key, map, result, _i, _len;
    map = {};
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      item = array[_i];
      key = accessor(item);
      if (map[key] == null) {
        map[key] = [];
      }
      map[key].push(item);
    }
    result = [];
    for (key in map) {
      items = map[key];
      result.push({
        key: key,
        items: items
      });
    }
    return result;
  };

  ViewModel = (function() {
    function ViewModel() {
      this.click = __bind(this.click, this);
      this.query = __bind(this.query, this);
      this.results = ko.observableArray([]);
      this.haserror = ko.observable(false);
    }

    ViewModel.prototype.query = function() {
      return $.get('api', (function(_this) {
        return function(results) {
          var check, checktype, grouping, result, _i, _j, _len, _len1, _ref, _results;
          _this.results.removeAll();
          results = groupby(results, function(r) {
            return r.name;
          });
          for (_i = 0, _len = results.length; _i < _len; _i++) {
            result = results[_i];
            _this.results.push({
              key: result.key,
              items: groupby(result.items, function(r) {
                return r.check;
              })
            });
          }
          _this.haserror(false);
          _ref = _this.results();
          _results = [];
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            grouping = _ref[_j];
            _results.push((function() {
              var _k, _len2, _ref1, _results1;
              _ref1 = grouping.items;
              _results1 = [];
              for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                checktype = _ref1[_k];
                _results1.push((function() {
                  var _l, _len3, _ref2, _results2;
                  _ref2 = checktype.items;
                  _results2 = [];
                  for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
                    check = _ref2[_l];
                    if (!check.isUp) {
                      _results2.push(this.haserror(true));
                    } else {
                      _results2.push(void 0);
                    }
                  }
                  return _results2;
                }).call(this));
              }
              return _results1;
            }).call(_this));
          }
          return _results;
        };
      })(this));
    };

    ViewModel.prototype.click = function(check) {
      return alert(check.message);
    };

    return ViewModel;

  })();

  $(function() {
    var vm;
    vm = new ViewModel;
    ko.applyBindings(vm);
    return vm.query();
  });

}).call(this);

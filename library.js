// Generated by CoffeeScript 1.7.1
var checks, dns, httpget, parallel, parseurl, ping, run, series,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

dns = require('dns');

ping = require('ping');

parseurl = require('url').parse;

httpget = require('http').get;

series = function(tasks, callback) {
  var next, result;
  tasks = tasks.slice(0);
  next = function(cb) {
    var task;
    if (tasks.length === 0) {
      return cb();
    }
    task = tasks.shift();
    return task(function() {
      return next(cb);
    });
  };
  result = function(cb) {
    return next(cb);
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};

parallel = function(tasks, callback) {
  var count, result;
  count = tasks.length;
  result = function(cb) {
    var task, _i, _len, _results;
    if (count === 0) {
      return cb();
    }
    _results = [];
    for (_i = 0, _len = tasks.length; _i < _len; _i++) {
      task = tasks[_i];
      _results.push(task(function() {
        count--;
        if (count === 0) {
          return cb();
        }
      }));
    }
    return _results;
  };
  if (callback != null) {
    result(callback);
  }
  return result;
};

checks = {
  dns: function(task, result, cb) {
    var host, ip, tasks, _fn, _ref;
    tasks = [];
    _ref = task.dns;
    _fn = function(host, ip) {
      return tasks.push(function(cb) {
        return dns.resolve4(host, function(err, addresses) {
          var a, skip, _i, _len;
          if (err != null) {
            result(task, 'dns', false, host, "" + host + " → ??? " + err, "There was an error looking up the DNS address. Either the address does not resolve to an IP address or this server is having DNS or connectivity issues. Have a look at the DNS server to see if it is correctly configured and have a look at this server's network to see if it is working correctly.");
            return cb();
          }
          if (addresses.length === 1 && addresses[0] === ip) {
            result(task, 'dns', true, host, "" + host + " → " + ip, "The DNS address correctly resolved.");
            return cb();
          }
          if (Object.prototype.toString.call(ip) === '[object Array]' && addresses.length === ip.length) {
            skip = false;
            for (_i = 0, _len = addresses.length; _i < _len; _i++) {
              a = addresses[_i];
              if (__indexOf.call(ip, a) < 0) {
                skip = true;
                break;
              }
            }
            if (!skip) {
              result('dns', true, host, "" + host + " → " + ip.length + " ip addresses", "The DNS address correctly resolved to multiple IP addresses.");
              return cb();
            }
          }
          result(task, 'dns', false, host, "" + host + " → " + addresses + " instead of " + ip, "The DNS address resolved to an unexpected address. The address may have been intentionally changed or we may be experiencing DNS issues. Have a look at the DNS server to see if it is correctly configured.");
          return cb();
        });
      });
    };
    for (host in _ref) {
      ip = _ref[host];
      _fn(host, ip);
    }
    return parallel(tasks, cb);
  },
  ping: function(task, result, cb) {
    var tasks;
    tasks = task.ping.map(function(host) {
      return function(callback) {
        return ping.sys.probe(host, function(isAlive) {
          if (!isAlive) {
            result(task, 'ping', false, host, "" + host + " is down", "The specified host did not respond to ping. This could because this server was not able to contact that IP address due to connectivity issues, or the host has been configured not to respond to ping, or the host is currently not running. Check to see if the host server is running.");
          } else {
            result(task, 'ping', true, host, "" + host + " is up", "The host responded to ping.");
          }
          return callback();
        });
      };
    });
    return parallel(tasks, cb);
  },
  http: function(task, result, cb) {
    var tasks;
    tasks = task.http.map(function(url) {
      return function(callback) {
        var chunks, code, hasReturned, href, key, options, port, req, value;
        code = 200;
        if (typeof url === 'object') {
          for (key in url) {
            value = url[key];
            href = key;
            code = value;
          }
          url = href;
        }
        chunks = parseurl(url);
        options = {
          hostname: chunks.hostname,
          port: chunks.port,
          path: chunks.path,
          agent: false
        };
        port = chunks.port;
        if (options.port == null) {
          if (chunks.protocol === 'https:') {
            options.port = 443;
          }
          if (chunks.protocol === 'http:') {
            options.port = 80;
          }
        }
        hasReturned = false;
        req = httpget(options, function(res) {
          if (hasReturned) {
            return;
          }
          if (res.statusCode === code) {
            result(task, 'http', true, url, "" + url + " responded", "The specified url responded to an http request.");
          } else {
            result(task, 'http', false, url, "" + url + " expected " + code + " received " + res.statusCode + " instead", "The url was requested successfully however the status code this server received was not expected. Normal content has a status code of 200. Status codes of 301 and 302 are redirects and are often used for login systems. Status codes of 400 means that the request this server made was bad. A status code of 403 means permission denied. 404 means not found and a status code of 500 means that there was an error on the server. If the status code returned is 500 the server needs to be looked at as the webserver is having an issue. Any other status codes are probably due to a configuration issue or this server is talking to the wrong server.");
          }
          hasReturned = true;
          return callback();
        }).on('error', function(err) {
          if (hasReturned) {
            return;
          }
          result(task, 'http', false, url, "" + url + " " + err.message, "An error occurred when attempting an http request. This is often a network issue. Look at the DNS for the destination server and this server's network connectivity.");
          hasReturned = true;
          return callback();
        });
        return req.setTimeout(5000, function() {
          if (hasReturned) {
            return;
          }
          result(task, 'http', false, url, "" + url + " timed out after 5 seconds", "5 seconds has elapsed with no response from the destination server. This happens when the destination server is not running a webserver, the destination server currently not running or this server is having network problems. Check the IP address for the destination server and make sure it responds to ping then check to see if the webserver is running correctly on the destination server.");
          hasReturned = true;
          return callback();
        });
      };
    });
    return parallel(tasks, cb);
  }
};

run = function(task, result, cb) {
  var check, f, tasks, _fn;
  if (Object.prototype.toString.call(task) === '[object Array]') {
    tasks = task.map(function(t) {
      return function(callback) {
        return run(t, result, callback);
      };
    });
    return parallel(tasks, cb);
  } else {
    tasks = [];
    _fn = function(check, f) {
      if (task[check] != null) {
        return tasks.push(function(cb) {
          return f(task, result, cb);
        });
      }
    };
    for (check in checks) {
      f = checks[check];
      _fn(check, f);
    }
    return series(tasks, cb);
  }
};

module.exports = run;

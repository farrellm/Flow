"use strict"

var app = angular.module('FlowApp', ['ui.bootstrap'])

app.controller("FlowCtrl", ['$scope', '$http', '$timeout', function ($scope, $http, $timeout) {
    $scope.console = {input: '',
                      output: ''};
    $scope.primaryTabs = [{name: 'Root'}, {name: 'New'}]

    // utility
    $scope.fetch = function(ks) { fetch($http, ks) }
    $scope.store = function(ks, v) { store($http, ks, v) }
    $scope.eval = function(text) { evaluate($http, text) }

    // poll for dirty state
    function tick() {
        dirty($http, function(data) {
            if (data.status == 'empty') {
                $timeout(tick, 100);
            } else {
                if (arraysEqual(data.keys, ["console", "input"]))
                    $scope.console.input = data.val
                else if (arraysEqual(data.keys, ["console", "output"]))
                    $scope.console.output = data.val

                $timeout(tick, 1);
            }
        })
    }
    tick()
}]);

app.controller("ConsoleCtrl", ['$scope', '$http', function ($scope, $http) {
    $scope.evalConsole = function (e) {
        if ((e.ctrlKey && e.keyCode == 13) || e.keyCode == 10) {
            evaluate($http, "Flow.eval_console()")
        }
    }

    // initialization
    fetch($http, 'console input', function (data) {
        $scope.console.input = data;
    })
    fetch($http, 'console output', function (data) {
        $scope.console.output = data;
    })
}])


function fetch($http, ks, success, error) {
    var res = $http.get("../../fetch", {params: {keys: ks}});
    if (success) {
        res.success(success)
    }
    if (error) {
        res.error(error)
    }
}
function store($http, ks, v) {
    $http.put("../../store", {}, {params: {keys: ks, val: v}})
}
function evaluate($http, text, success, error) {
    var res = $http.get("../../eval", {params: {text: text}})
    if (success) {
        res.success(success);
    }
    if (error) {
        res.error(error)
    }
}

function dirty($http, success) {
    var res = $http.get("../../dirty");
    res.success(success)
}


// https://stackoverflow.com/questions/3115982/how-to-check-javascript-array-equals
function arraysEqual(a, b) {
  if (a === b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;

  // If you don't care about the order of the elements inside
  // the array, you should sort both arrays here.

  for (var i = 0; i < a.length; ++i) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

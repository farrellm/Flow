"use strict"

var app = angular.module('FlowApp', ['ui.bootstrap'])

var FlowCtrl = function($scope, $http, $timeout, $modal) {
    $scope.console = {input: '', output: ''};
    $scope.primaryTabs = [];
    $scope.state = {activeTabId: 0}

    fetch($http, 'active_tab_id', function (idData) {
        fetch($http, 'tabs', function (data) {
            if (data.value.length == 0) {
                $scope.eval('new_tab("new")')
            } else {
                $scope.primaryTabs = data.value
                $scope.setActivePrimaryTab(idData.value)
            }
        })
    })

    // utility
    $scope.fetch = function(ks) { fetch($http, ks) }
    $scope.store = function(ks, v) { store($http, ks, v) }
    $scope.eval = function(text) { evaluate($http, text) }

    $scope.newTab = function() {
        // reset from '+' tab
        $scope.setActivePrimaryTab($scope.state.activeTabId)

        var modalInstance = $modal.open({
            templateUrl: 'newTabContent.html',
            controller: NewTabCtrl,
            size: "sm"
        })

        modalInstance.result.then(function (name) {
            evaluate($http, 'new_tab("' + name + '")', function (data) {
                $scope.setActivePrimaryTab(data.value)
            })
        })
    }

    $scope.setActivePrimaryTab = function(id) {
        if (typeof id != 'undefined') {
            angular.forEach($scope.primaryTabs, function(pt) {
                pt.active = (pt.id == id)
            })

            if (id != $scope.state.activeTabId) {
                $scope.state.activeTabId = id
                store($http, ['active_tab_id'], id)
            }
        }
    }

    // poll for dirty state
    function tick() {
        dirty($http, function(res) {
            if (res.status == 'empty') {
                $timeout(tick, 100);
            } else {
                console.log("dirty " + JSON.stringify(res.keys))
                if (arraysEqual(res.keys, ["console", "input"]))
                    $scope.console.input = res.value
                else if (arraysEqual(res.keys, ["console", "output"]))
                    $scope.console.output = res.value
                else if (arraysEqual(res.keys, ["tabs"])) {
                    var activeTabId = $scope.state.activeTabId
                    $scope.primaryTabs = res.value

                    // reset to last active tab
                    $timeout(function() {
                        $scope.setActivePrimaryTab(activeTabId)
                    }, 1)
                } else if (arraysEqual(res.keys, ["active_tab_id"]))
                    $scope.setActivePrimaryTab(res.value)
                else
                    alert("Unknown key: " + JSON.stringify(res.keys))

                $timeout(tick, 1);
            }
        })
    }
    tick()
}

app.controller("PrimaryTabCtrl", function ($scope) {
    $scope.init = function (id) {
        $scope.id = id
    }
    $scope.onSelect = function () {
        $scope.setActivePrimaryTab($scope.id)
    }
})

app.controller("ConsoleCtrl", function ($scope, $http) {
    $scope.evalConsole = function (e) {
        if ((e.ctrlKey && e.keyCode == 13) || e.keyCode == 10) {
            evaluate($http, "Flow.eval_console()")
        }
    }

    // initialization
    $scope.isCollapsed = true
    fetch($http, 'console input', function (res) {
        $scope.console.input = res.value
    })
    fetch($http, 'console output', function (res) {
        $scope.console.output = res.value
    })
})

var NewTabCtrl = function ($scope, $modalInstance) {
    $scope.name = {value: ""}

    $scope.ok = function () {
        $modalInstance.close($scope.name.value)
    }

    $scope.cancel = function () {
        $modalInstance.dismiss('cancel')
    }
}

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
    $http.put("../../store", {}, {params: {keys: ks, val: encodeURIComponent(v)}})
}
function evaluate($http, text, success, error) {
    var res = $http.get("../../eval", {params: {text: encodeURIComponent(text)}})
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

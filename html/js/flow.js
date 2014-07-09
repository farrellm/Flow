var app = angular.module('FlowApp', [])

app.controller("FlowCtrl", function($scope, $http) {
    $scope.consoleInput = '';
    $scope.consoleOutput = '';

    $scope.evalConsole = function (e) {
	if ((e.ctrlKey && e.keyCode == 13) || e.keyCode == 10) {
	    eval($http, "Flow.eval_console()", function () {
		fetch($http, 'console output', function (data) {
		    $scope.consoleOutput = data
		})
	    })
	}
    }

    // utility
    $scope.fetch = function(ks) { fetch($http, ks) }
    $scope.store = function(ks, v) { store($http, ks, v) }
    $scope.eval = function(text) { eval($http, text) }

    // initialization
    fetch($http, 'console input', function (data) {
	$scope.consoleInput = $.parseJSON(data)
    })
    fetch($http, 'console output', function (data) {
	$scope.consoleOutput = $.parseJSON(data)
    })
});


function fetch($http, ks, success, error) {
    var res = $http.get("../../fetch", {params: {keys: ks}});
    res.success(success);
    res.error(error)
}
function store($http, ks, v) {
    $http.put("../../store", {}, {params: {keys: ks, val: v}})
}
function eval($http, text, success, error) {
    var res = $http.get("../../eval", {params: {text: text}})
    res.success(success);
    res.error(error)
}


$( "#primary-tabs" ).tabs({heightStyle: "fill"});

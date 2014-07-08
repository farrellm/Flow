$(function() {
    $( "#primary-tabs" ).tabs({heightStyle: "fill"});

    $("#console-input").keydown(function (e) {
	if (e.ctrlKey && e.keyCode == 13) {
            EvalConsole(e)
	}
    })
});

function EvalConsole(e) {
    text = $("#console-input").val()
    $("#console-output").val("...")
    res = $.get("../eval",
	    	"text=" + encodeURIComponent(text),
		function(data) {
		    $("#console-output").val(data)
		})
}

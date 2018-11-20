"use strict";
var webpage = require('webpage');
var system = require('system');
var fs = require('fs');

var args = system.args;
var page = webpage.create();

page.onConsoleMessage = function(msg, lineNum, sourceId) {
  console.log('CONSOLE: ' + msg + ' (from line #' + lineNum + ' in "' + 
              sourceId + '")');
};
page.viewportSize = { width: "600px", height: "600px" };
page.open(args[1], function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
        phantom.exit(1);
    } else {
        page.injectJs("layout.js");
        var layout = page.evaluate(function() { return calculateLayout() });
        fs.write(args[2], layout, "w");
        phantom.exit();
    }
});

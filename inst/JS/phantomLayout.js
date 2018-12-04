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
page.viewportSize = { width: args[2] + "px", height: args[3] + "px" };
page.open(args[1], function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
        phantom.exit(1);
    } else {
        // Workaround to force document to desired size 
        // (setting page.viewportSize() above is not enough)
        // https://stackoverflow.com/questions/13390859/viewportsize-seems-not-to-work-with-phantomjs
        page.evaluate(function(w, h) {
            document.body.style.width = w + "px";
            document.body.style.height = h + "px";
        }, args[2], args[3]);
        page.injectJs("font-baseline.js");
        page.injectJs("layout.js");
        var layout = page.evaluate(function() { return calculateLayout() });
        fs.write(args[4], layout, "w");
        phantom.exit();
    }
});

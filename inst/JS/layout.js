
function writeBox(node) {
    var line = "";
    if (node.nodeType == Node.ELEMENT_NODE) {
        line = line + node.nodeName + ",";
        var bbox = node.getBoundingClientRect();
        line = line + bbox.left + ",";
        line = line + bbox.top + ",";
        line = line + bbox.width + ",";
        line = line + bbox.height + ",,,,,\n";
        // console.log(line);
        var i;
        var children = node.childNodes;
        for (i=0; i<children.length; i++) {
            line = line + writeBox(children[i]);
        }
    } else if (node.nodeType == Node.TEXT_NODE &&
               !/^\s*$/.test(node.nodeValue)) {
        line = line + "TEXT,";
        // Use document.createRange(), Range.selectNodeContents(<text node>),
        // and Range.getBoundingClientRect() ?
        // as per https://stackoverflow.com/questions/6961022/measure-bounding-box-of-text-node-in-javascript
        var parent = node.parentElement;
        if (true) {
            var range = document.createRange();
            range.selectNodeContents(node);
            var bbox = range.getBoundingClientRect();
        } else {
            var bbox = parent.getBoundingClientRect();
        }
        line = line + bbox.left + ",";
        line = line + bbox.top + ",";
        line = line + bbox.width + ",";
        line = line + bbox.height + ",";
        line = line + node.nodeValue + ",";
        var style = window.getComputedStyle(parent);
        line = line + style["font-family"] + ",";
        line = line + (style["font-weight"] > 500) + ",";
        line = line + (style["font-style"] != "normal") + ",";
        line = line + style["font-size"].replace("px", "") + "\n";
    } else {
        // just a comment;  do nothing
    }
    return line;
}

function calculateLayout() {
    var body = document.body;
    var csv = "BODY," + 0 + "," + 0 + "," + 
        body.offsetWidth + "," + body.offsetHeight + "\n";
    var i;
    var children = body.childNodes;
    for (i=0; i<children.length; i++) {
        csv = csv + writeBox(children[i]);
    }
    return csv;
}

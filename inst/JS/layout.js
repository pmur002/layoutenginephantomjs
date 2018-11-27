
// Use element 'id' if that exists, 
// otherwise, element tag name plus child index
function elementName(node, index, parentName) {
    var tagName = node.nodeName;
    var id = node.getAttribute("id");
    if (id != null) {
        return parentName + "." + tagName + "." + id;
    } else {
        return parentName + "." + tagName + "." + index;
    }
}

function textName(index, parentName) {
    return parentName + ".TEXT." + index;
}

function borderWidth(style, border) {
    return style[border].replace("px", "");
}

function hexColor(rgb) {
    var pieces = rgb.split(/[,()]/);
    var red = Number(pieces[1]).toString(16);
    if (red.length < 2) red = "0" + red;
    var green = Number(pieces[2]).toString(16);
    if (green.length < 2) green = "0" + green;
    var blue = Number(pieces[3]).toString(16);
    if (blue.length < 2) blue = "0" + blue;
    var alpha = "FF";
    if (pieces.length > 5) {
        alpha = Number(pieces[4]).toString(16);
        if (alpha.length < 2) alpha = "0" + alpha;
    }
    return "#" + red + blue + green + alpha;
}

function writeBox(node, index, parentName) {
    var line = "";
    if (node.nodeType == Node.ELEMENT_NODE) {
        line = line + node.nodeName + ",";
        var elName = elementName(node, index, parentName);
        line = line + elName + ",";
        var bbox = node.getBoundingClientRect();
        line = line + bbox.left + ",";
        line = line + bbox.top + ",";
        line = line + bbox.width + ",";
        line = line + bbox.height + ",";
        // No text information (text, family, bold, italic, size, color)
        line = line + "NA,NA,NA,NA,NA,NA" + ",";
        var style = window.getComputedStyle(node);
        line = line + hexColor(style["background-color"]) + ",";
        // Borders
        line = line + borderWidth(style, "border-left-width") + ",";
        line = line + borderWidth(style, "border-top-width") + ",";
        line = line + borderWidth(style, "border-right-width") + ",";
        line = line + borderWidth(style, "border-bottom-width") + ",";
        line = line + style["border-left-style"] + ",";
        line = line + style["border-top-style"] + ",";
        line = line + style["border-right-style"] + ",";
        line = line + style["border-bottom-style"] + ",";
        line = line + hexColor(style["border-left-color"]) + ",";
        line = line + hexColor(style["border-top-color"]) + ",";
        line = line + hexColor(style["border-right-color"]) + ",";
        line = line + hexColor(style["border-bottom-color"]);
        line = line + "\n";
        // console.log(line);
        var i;
        var children = node.childNodes;
        for (i=0; i<children.length; i++) {
            line = line + writeBox(children[i], i + 1, elName);
        }
    } else if (node.nodeType == Node.TEXT_NODE &&
               !/^\s*$/.test(node.nodeValue)) {
        line = line + "TEXT,";
        line = line + textName(index, parentName) + ",";
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
        // Text 
        line = line + "'" + node.nodeValue + "'" + ",";
        var style = window.getComputedStyle(parent);
        line = line + style["font-family"] + ",";
        line = line + ((style["font-weight"] == "bold" ||
                        style["font-weight"] > 500)?"TRUE":"FALSE") + ",";
        line = line + ((style["font-style"] != "normal")?"TRUE":"FALSE") + ",";
        line = line + style["font-size"].replace("px", "") + ",";
        line = line + hexColor(style["color"]) + ",";
        // No background
        line = line + "NA,";
        // No border properties (width, style, color)
        line = line + "NA,NA,NA,NA,";
        line = line + "NA,NA,NA,NA,";
        line = line + "NA,NA,NA,NA";
        line = line + "\n";
    } else {
        // just a comment;  do nothing
    }
    return line;
}

function calculateLayout() {
    var body = document.body;
    var csv = "BODY,BODY.1," + 0 + "," + 0 + "," + 
        body.offsetWidth + "," + body.offsetHeight + "\n";
    var i;
    var children = body.childNodes;
    for (i=0; i<children.length; i++) {
        csv = csv + writeBox(children[i], i + 1, "BODY.1");
    }
    return csv;
}

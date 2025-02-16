const FS = require("fs");
const PATH = require("path");

exports.writeJSON = function(location, data) {
    FS.writeFileSync(PATH.join(__dirname, location), JSON.stringify(data));  
}
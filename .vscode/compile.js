var fs = require('fs');
var http = require('http');

var opt =   JSON.parse(fs.readFileSync('./.vscode/opt.json', 'utf8'));
var userFile = process.argv[2];
var sourceFile = process.argv[3];
var format = process.argv[4];

var file = userFile;
if (opt.root) {
    var rootPosition = file.toLowerCase().indexOf(opt.root.toLowerCase());
    if (rootPosition > -1) {
        file = file.substring(rootPosition);
    }
}
console.log("Submitting file " + file + " to " + opt.server + " (" + opt.id + ")");

var host = opt.server + '/.0/system/crticepgm?';
var purl  = "userFile=" + userFile + "&format=" + format + "&source=" + sourceFile;
var serverid   =  '&server=' + opt.id;

var p = http.get(host + purl + serverid, function(response) {
    var body = '';
    response.on('data', function(d) {
        body += d;
    });
    response.on('end', function() {
        console.log(body);
    });
});

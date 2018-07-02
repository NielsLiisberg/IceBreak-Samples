var http = require('http');
var fs = require('fs');
var opt =   JSON.parse( fs.readFileSync('./.vscode/opt.json', 'utf8'));
var purl  = process.argv[2];
var host = opt.server + '/.0/system/crticepgm?'
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

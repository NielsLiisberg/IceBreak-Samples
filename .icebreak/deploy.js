const { promises: fs } = require("fs")
const http = require("http")
const util = require("util")
const os = require("os")
const { exit } = require("process")
let cnt =100

function log(msg) {
    console.log(`.icebreak/deploy.json:1:${cnt++}:info>${msg}`)
}
function httpRequest(config , params, postData , isJson) {
    const protocol = config.serverUrl.split('://')[0]
    const svrprt   = config.serverUrl.split('://')[1]
    params.host = svrprt.split(':')[0]
    params.port = svrprt.split(':')[1]

    //!! console.log(params)

    return new Promise(function(resolve, reject) {
        var req = http.request(params, function(res) {
            // reject on bad status
            if (res.statusCode < 200 || res.statusCode >= 300) {
                log(source, `Server ${config.serverId } is not responing. reason ${res.statusCode}` )
                return reject(new Error('statusCode=' + res.statusCode));
            } 
            // cumulate data
            var body = [];
            res.on('data', function(chunk) {
                body.push(chunk);
            });
            // resolve on end
            res.on('end', function() {
                if (isJson) {
                    try {
                        body = JSON.parse(Buffer.concat(body).toString());
                    } catch(e) {
                        log(Buffer.concat(body).toString())
                        log(e)
                        reject(e);
                    }
                    resolve(body);
                } else {
                    resolve(Buffer.concat(body).toString());
                }
            });
        });
        // reject on request error
        req.on('error', (err) => {
            // This is not a "Second reject", just a different sort of failure
            log(`Server ${config.serverId } is not responding. reason ${err}`)
            reject(err);
        });
        if (postData) {
            req.write(postData);
        }
        // IMPORTANT
        req.end();
    });
}

async function main()  {

    let config =   JSON.parse( await fs.readFile('./.icebreak/config.json', 'utf8'))
    const deployListFile = './.icebreak/deploy.json'
    let deployList
    try {
        deployList  =   await fs.readFile(deployListFile, 'utf8')
    } catch(e) {
        log("Nothing to deploy") 
        exit(0)
    }

    let result = await httpRequest (
        config,
        {
            method: 'POST', 
            path: `/.0/system/svctools?func=deploy&profile=${config.profile}&teamtoken=${config.teamToken}`,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': deployList.length,
                'transfer-encoding' : ''
            }
        } , 
        deployList,
        false
    )
    result.split('\n').forEach( (t) => {
        log(t)
    })
    await fs.writeFile(deployListFile, '[]' , 'utf8')
    return Promise.resolve(true)
}
main ()

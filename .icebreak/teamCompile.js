const { promises: fs } = require("fs")
const http = require("http")
const util = require("util")
const os = require("os")
const { exit } = require("process")
const source = process.argv[3]
let poscnt = 100

function log(source, msg) {
    console.log(`${source}:1:1:error: Compiler terminated. ${msg.replace(/:/g,';')}`)
}
function info(source, msg) {
    console.log(`${source}:1:${poscnt++}:info: ${msg}`)
}

function httpRequest(config , params, postData , isJson) {
    const protocol = config.serverUrl.split('://')[0]
    const svrprt   = config.serverUrl.split('://')[1]
    params.host = svrprt.split(':')[0]
    params.port = svrprt.split(':')[1]

    ////! console.log(params)

    
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
                        log(source, Buffer.concat(body).toString())
                        log(source, e)
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

function buildLookupList(result) {
    let lookupList = {}
    for (const file of result) {
        lookupList[file.path.toLowerCase()] = {
            size : file.size,
            changed : file.changed
        }
    }
    return lookupList
}
function toSec(s) {
    let ds  = `${s.substr(0,10)}T${s.substr(11,2)}:${s.substr(14,2)}:${s.substr(17,2)}.000Z`
    let d = Date.parse (ds)
    return parseInt(d / 1000)
}

function needUpload(config, lookupList, dirent , stat) {

    const fileName = (dirent).toLowerCase()
    // console.log(fileName)
    
    // never upload meta data
    if (dirent.indexOf('.git') >= 0
    ||  dirent.indexOf('.vscode') >= 0
    ||  dirent.indexOf('.DS_Store') >= 0) {
        return false
    }
    
    
    /// console.log('F: ' , lookupList , fileName);
    
    const serverfile  = lookupList[fileName];

    if ( ! serverfile) {
        return true
    }

    const serverFileTime = toSec(serverfile.changed)
    const localFileTime  = parseInt(stat.mtimeMs/1000)

    // console.log('TS: ' , serverFileTime , ' : ' , localFileTime);

    if (serverFileTime  != localFileTime ) {
        console.log('Upload : ' , fileName);
        return true
    }

    // The two bytes bomcode is OK - !!!! TODO better check and upload binary
    const sizeDif =  Math.abs(parseInt(serverfile.size)  - stat.size) 
    if (sizeDif > 2) {
        // console.log('Upload : ' , fileName);
        return true
    } 
    // File is the same
    return false
}


async function upload  (config, filename , modtime) {
    //filename = './' + filename
    // console.log(filename)
    let filedata =  await fs.readFile(filename)
    let filenameuri =  encodeURIComponent(filename)
    let result = await httpRequest (
        config,
        {
            method: 'POST', 
            path: `/.0/system/svctools?func=upload&filename=${filenameuri}&profile=${config.user}&modtime=${modtime}`,
            headers: {
                'Content-Type': 'octet/stream',
                'Content-Length': filedata.length,
                'transfer-encoding' : ''
            }
        } , 
        filedata,
        true
    )
    return Promise.resolve(result)
}

async function compile  (config) {
    //const purl  = `userFile=${config.userFile}&format=${config.format}&source=${config.sourceFile}&server=${config.serverId}&objlib=${config.targetLibrary}&profile=${config.user}&teamtoken=${config.teamToken}` 
    const purl  = `format=${config.format}&source=${config.sourceFile}&server=${config.serverId}&objlib=${config.targetLibrary}&profile=${config.user}&teamtoken=${config.teamToken}` 
    const result = await httpRequest (config, {method: 'GET', path: '/.0/system/svctools?func=compile&' + purl},null,false)
    ok = result.indexOf (' OK ') > 0 // TODO !! Need better success detection  
    console.log(result)
    return Promise.resolve(ok)
}

async function scanDir(config , lookupList , startDir) {
    let dirents = await fs.readdir(startDir);  
    for (const dirent of dirents) {
        let absname = startDir + '/' + dirent
        let stat = await fs.stat(absname)
        //console.log("Name: " + absname)
        //console.log("dirent: " + dirent)
        //console.log(stat.isDirectory()? "dir" : "file")

        if ( stat.isDirectory()) {
            if (dirent.substr(0,1) != '.') {
                await scanDir(config, lookupList, absname )
            }
        } else {
            if (needUpload(config, lookupList, absname , stat)) {
                ////! console.log("Upload " + dirent );
                res = await upload(config, absname , parseInt(stat.mtimeMs / 1000) )
            }
        }
    }
    return Promise.resolve(true)
}

function source2object (source) {
    let obj = source.split('/')
    obj = obj[obj.length-1] // Last element
    obj = obj.split('.')[0] // Evrything before the dot
    return obj.toUpperCase()
}

async function appendToDeploylist(config) {
    // Append to compile list if not in the list
    const deployListFile = './.icebreak/deploy.json'
    let deployList
    try {
        deployList  =   JSON.parse( await fs.readFile(deployListFile, 'utf8'))
    } catch(e) {
        deployList = []
    }

    let object =  {
        "library" : config.targetLibrary,
        "object"  : config.objectName 
    }

    let found  = deployList.find((o)=> {
        return ( o.library == object.library && o.object == object.object)
    }) 
        
    if (! found) {
        deployList.push(object)
        await fs.writeFile(deployListFile, JSON.stringify (deployList) , 'utf8')
    } 
    return Promise.resolve(true)
}



async function main () {

    let result
    let config =   JSON.parse( await fs.readFile('./.icebreak/config.json', 'utf8'))
    config.userFile   = process.argv[2]
    config.sourceFile = process.argv[3]
    config.objectName = source2object(config.sourceFile)

    if (! config.profile || config.profile.substr(0,1) == '*') {
        config.user = os.userInfo().username     
    } else {
        config.user = config.profile     
    }

    if (! config.targetLibrary || config.targetLibrary.substr(0,1) == '*') {
        log(".icebreak/config.json" ,"You need to set your user profile and targetlibrary (private library) in the  .icebreak/config.json file")
        exit(0)
    }

    console.log("Submitting file " + config.userFile  + " to " + config.serverUrl + " (" + config.serverId + ")");
    
    try {
        result = await httpRequest (config , { method: 'POST', path: `/.0/system/svctools?func=listdir&profile=${config.user}`},null, true)
    } catch(err) {
        return;
    }
    ////! console.log(result)
    let lookupList = buildLookupList(result);

    await scanDir(config , lookupList , '.')
    ok = await compile (config)
    if (ok) {
        info(source, `Click on Team activation link below to run your private service layer`)
        info(source, `${config.serverUrl}/system/svcTools?func=setteam&profile=${config.profile}&library=${config.targetLibrary}&teamToken=${config.teamToken}`)
        await appendToDeploylist(config)
    }
};
main ()

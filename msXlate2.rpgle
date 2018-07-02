<%@ language="RPGLE" %>
<%
ctl-opt copyright('System & Method (C), 2016');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('NOXDB');
// ---------------------------------------------------------
// translate text using watson API and noxDB:
//
//       https://watson-api-explorer.mybluemix.net/
// 
// By     Date       PTF     Description
// ------ ---------- ------- ------------------------------  
// NLI    22.06.2016         New program
// ---------------------------------------------------------
/include noxdb
 
dcl-proc main;

    dcl-s  pResponse        pointer;
    dcl-s  pRequest         pointer;
    dcl-s  url              varchar(1024);
    dcl-s  text             char(52);

    // Build the request JSON object
    pRequest = json_newObject();
    json_setStr (pRequest : 'source'   : 'en');
    json_setStr (pRequest : 'target'   : 'es');
    json_setStr (pRequest : 'text'     : 'Hello my friend');


    url = 'https://watson-api-explorer.mybluemix.net' +
          '/language-translator/api/v2/translate';
    
    // The "JSON in, JSON out" call
    // Note: Extra cURL parameters can be placed from parm 3 
    pResponse = json_httpRequest (url: pRequest);

    // Just debug the response
    text = json_getStr(pResponse: 'translations[0].translation':'N/A');
    dsply ( text ) ;

    // Remember to clean up: Both the request and the response     
    json_delete(pRequest);
    json_delete(pResponse);

end-proc;

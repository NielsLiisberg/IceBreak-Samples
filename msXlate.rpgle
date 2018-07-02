<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/msXlate.rpgle') SVRID(samples)


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2018         New program
  ----------------------------------------------------------------------------- */
 /include noxdb
 
/* -------------------------------------------------------------------- *\ 
   	translate text using watson API:

	   https://watson-api-explorer.mybluemix.net/
	    
	dksrv206:60060/router?payload={
		"action": "msXlate.translate",
		"source": "en",
		"target": "es",
		"text"  : "Good afternoon my friends"
	}

\* -------------------------------------------------------------------- */
dcl-proc translate export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pOutput      	pointer;
	dcl-s  pReq   	  		pointer;
	dcl-s  url  	  		varchar(1024);
	dcl-s  text 	  		varchar(4096);

    pReq = json_newObject();
    json_copyValue (pReq : 'source'   : pInput : 'source');
    json_copyValue (pReq : 'target'   : pInput : 'target');
	json_copyValue (pReq : 'text'     : pInput : 'text');

    url = 'https://watson-api-explorer.mybluemix.net' +
		  '/language-translator/api/v2/translate';
    
    pOutput = json_httpRequest  (url: pReq);

	json_delete(pReq);

	// Just debug the response
	text = json_getStr(pOutput : 'translations[0].translation' : 'N/A');
	setHeader ( '1-debug' : text);
	
    return (pOutput);

end-proc;


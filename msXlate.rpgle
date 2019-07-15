<%@ free="true" language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/msXlate.rpgle') SVRID(samples)


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2019         New program
  ----------------------------------------------------------------------------- */
 /include noxdb
 
/* -------------------------------------------------------------------- *\ 
   	translate text using watson API:


	https://watson-api-explorer.mybluemix.net/
		
	http://sandbox.icebreak.org:60060/router?payload={
		"action"  : "msXlate.translate",
		"model_id": "en-es",
		"text"    : "Good afternoon my friends"
	}

	This requires:
	
		yum install curl

	And set the path system wide once:
	ADDENVVAR ENVVAR(PATH)                                                          
          VALUE('/QOpenSys/pkgs/bin:/QOpenSys/usr/bin:/usr/ccs/bin:/QOpenSys/usr
/bin/X11:/usr/sbin:.:/usr/bin')                                                 
                  LEVEL(*SYS)                                                   
		

\* -------------------------------------------------------------------- */
dcl-proc translate export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pOutput      	pointer;
	dcl-s  pReq   	  		pointer;
	dcl-s  url  	  		varchar(1024);
	dcl-s  text 	  		varchar(4096);
	dcl-s  extraParms  		varchar(4096);
	dcl-c  appkey  		    'ZiVLkVMPE7-ECxvEaJIbZ5nD4QS63bUM63ww-ZxXOi_w'; // <<< Put your applicaton key here

	pReq  = json_newObject();
	
	json_copyValue (pReq : 'model_id' : pInput : 'model_id');
	json_copyValue (pReq : 'text'     : pInput : 'text');
	
	url = 'https://gateway.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01';
	
	extraParms = '-k --user apikey:' + appkey;
	pOutput = json_httpRequest  (url: pReq : extraParms);

	json_delete(pReq);

	// Just debug the response
	text = json_getStr(pOutput : 'translations[0].translation' : 'N/A');
	consoleLog(text);

	return (pOutput);

end-proc;


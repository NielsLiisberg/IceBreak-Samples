<%@ language="RPGLE" %>
<%
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('NOXDB':'ICEUTILITY':'QC2LE');

/* -----------------------------------------------------------------------------
   Service . . . : microservice router
   Author  . . . : Niels Liisberg 
   Company . . . : System & Method A/S
  
   CRTICEPGM STMF('/www/IceBreak-Samples/router.rpgle') SVRID(samples)
   
   By     Date       PTF     Description
   ------ ---------- ------- ---------------------------------------------------
   NLI    10.05.2019         New program
   NLI    23.01.2026         Refactored for REST only (no Seneca)
   ----------------------------------------------------------------------------- */
 /include qasphdr,jsonparser
 /include qasphdr,iceutility
 
// --------------------------------------------------------------------
// Main line:
// --------------------------------------------------------------------
dcl-proc main;
	
	dcl-s pResponse		pointer;		
	dcl-s pPayload       pointer;

	initialize(); 

	pPayload = unpackParms();

	pResponse = runService (pPayload);
	if (pResponse = *NULL);
		responseWrite('null');
	else;
		responseWriteJson(pResponse);
		if json_getstr(pResponse : 'success') = 'false';
			setStatus ('500 ' + json_getstr(pResponse: 'message'));
			consoleLogjson(pResponse);
		endif;
	endif;

on-exit; 
	json_delete (pPayload);
	json_delete (pResponse);

end-proc;
/* -------------------------------------------------------------------- *\  
   initialize the roundtrip
\* -------------------------------------------------------------------- */
dcl-proc initialize;

	SetContentType('application/json; charset=utf-8');
	SetEncodingType('*JSON');
	json_setDelimiters('/\@[] .{}''"$');
	json_sqlSetOptions('{'             + // use dfault connection
		'upperCaseColname: false,   '  + // set option for uppcase of columns names
		'autoParseContent: true,    '  + // auto parse columns predicted to have JSON or XML contents
		'sqlNaming       : false    '  + // use the SQL naming for database.table  or database/table
	'}');

end-proc;
/* -------------------------------------------------------------------- *\  
   get pauload data form request and build JSON graph
\* -------------------------------------------------------------------- */
dcl-proc unpackParms;

	dcl-pi *n pointer;
	end-pi;

	dcl-s pPayload 		pointer;
	dcl-s msg     		varchar(4096);

	if reqStr('payload') > '';
		pPayload = json_ParseString(reqStr('payload'));
	else;
		pPayload = json_ParseRequest();
		if pPayload = *NULL;
			pPayload = json_newObject(); // just an empty object;
		endif;
	endif;

	return pPayload;


end-proc;
/* -------------------------------------------------------------------- *\ 
   	run a JSON-in/JSON-out microservice call
\* -------------------------------------------------------------------- */
dcl-proc runService export;	

	dcl-pi *n pointer;
		pPayload pointer value;
	end-pi;

	dcl-pr actionProc pointer extproc(pProc);
		payload pointer value;
	end-pr;
	
	dcl-s pResponse		pointer;		
	dcl-s action  		varchar(128);
	dcl-s prevAction  	varchar(128) static;
	dcl-s pgmName 		char(10);
	dcl-s procName 		varchar(128);
	dcl-s pProc			pointer (*PROC) static;
	dcl-s errText  		char(128);
	dcl-s errPgm   		char(64);
	dcl-s errList 		char(4096);
  	dcl-s len 			int(10);

	// Get the action from the request URL
	// Example: /router/msSimple/divide 
	// gives msSimple as program and divide as procedure
	// note: case insensitive: if you export your procedure as DCLCASE 
	// The do not use the strUpper on procName. 
	action = strUpper(getServerVar('REQUEST_FULL_PATH'));
	len = words(action:'/');
	pgmName  = word (action:len-1:'/');
	procName = word (action:len:'/');

	// Now the IceBreak magic: 
	// Dynamically load the service program and procedure
	// so no static binding is needed.
	pProc = loadServiceProgramProc ('*LIBL': pgmName : procName);

	// You could optimize by caching the pProc pointer
	// but the overhead of loadServiceProgramProc is minimal
	// compared to the actual service execution.
	//  if  action <> prevAction;
	//	   prevAction = action;
	//     pProc = loadServiceProgramProc ('*LIBL': pgmName : procName);
	//  endif;

	if (pProc = *NULL);
		pResponse= formatError (
			'Invalid action: ' + action + ' or service not found'
		);
	else;
		monitor;

		pResponse = actionProc(pPayload);

		on-error;                                     
			soap_Fault(errText:errPgm:errList);    
			pResponse =  formatError (
				'Error in service ' + action + ', ' + errText
			);
		endmon;                                       	

	endif;

	return pResponse; 

end-proc;

/* -------------------------------------------------------------------- *\ 
   JSON error monitor 
\* -------------------------------------------------------------------- */
dcl-proc formatError export;

	dcl-pi *n pointer;
		description  varchar(256) const options(*VARSIZE);
	end-pi;                     

	dcl-s msg 					varchar(4096);
	dcl-s pMsg 					pointer;

	msg = json_message(*NULL);
	pMsg = json_parseString (' -
		{ -
			"success": false, - 
			"description":"' + description + '", -
			"message": "' + msg + '"-
		} -
	');

	consoleLog(msg);
	return pMsg;


end-proc;
/* -------------------------------------------------------------------- *\ 
   JSON error monitor 
\* -------------------------------------------------------------------- */
dcl-proc successTrue export;

	dcl-pi *n pointer;
	end-pi;                     

	return json_parseString ('{"success": true}');

end-proc;

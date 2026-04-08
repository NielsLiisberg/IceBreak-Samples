**free
//<%@ language="RPGLE" %>
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt option(*nodebugio:*srcstmt:*nounref);
ctl-opt bndDir('NOXDB':'ICEBREAK':'ICEUTILITY');
//  -----------------------------------------------------------------------------
//  Service . . . : microservice router
//  Author  . . . : Niels Liisberg 
//  Company . . . : System & Method A/S
// 
//  CRTICEPGM STMF('/www/IceBreak-Samples/router.rpgle') SVRID(samples)
//  
//  By     Date       PTF     Description
//  ------ ---------- ------- ---------------------------------------------------
//  NLI    10.05.2019         New program
//  NLI    23.01.2026         Refactored for REST only (no Seneca)
//  ----------------------------------------------------------------------------- 
 /include qrpgleref,icebreak
 /include qrpgleref,iceutility
 /include qrpgleref,jsonparser
 
//  ----------------------------------------------------------------------------- 
//  Main line:
//  ----------------------------------------------------------------------------- 
dcl-proc main;
	
	dcl-s pResponse		pointer;		
	dcl-s pPayload       pointer;

	initialize(); 
	pPayload = unpackParms();
	pResponse = runService (pPayload);
	sendResponse(pResponse);

on-exit; 
	json_delete (pPayload);
	json_delete (pResponse);

end-proc;
//  ----------------------------------------------------------------------------- 
//  initialize the roundtrip
//  ----------------------------------------------------------------------------- 
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
//  ----------------------------------------------------------------------------- 
//  get payload data form request and build JSON graph
//  note: for production use HTTP POST with JSON payload in body
//  not the URL GET parameter ?payload= but this is ok for testing
//  ----------------------------------------------------------------------------- 
dcl-proc unpackParms;

	dcl-pi *n pointer;
	end-pi;

	dcl-s pPayload 		pointer;

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
// -------------------------------------------------------------------- 
//  Run a JSON-in/JSON-out microservice call
// 	load the service program and procedure dynamically
// 	based on the URL path, and call the procedure that will
// 	be JSON-in/JSON-out. 
// 
// 	note: You could optimize by caching the pProc pointer
// 	but the overhead of loadServiceProgramProc is minimal
// 	compared to the actual service execution.
// 
// 	if  action <> prevAction;
// 	   	prevAction = action;
// 		pProc = loadServiceProgramProc ('*LIBL': pgmName : procName);
// 	endif;
// 
// -------------------------------------------------------------------- 
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
	// Example: /router/mySrvPgm/myProcedure 
	// gives mySrvPgm as service program and myProcedure as procedure
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
// -------------------------------------------------------------------- 
// send response to client	
// --------------------------------------------------------------------
dcl-proc sendResponse;

	dcl-pi *n;
		pResponse pointer value;
	end-pi;

	if (pResponse = *NULL);
		setStatus ('204 No response');
		responseWrite('null');
	else;
		if json_getstr(pResponse : 'success') = 'false';
			setStatus ('500 ' + json_getstr(pResponse: 'msg'));
			consoleLogjson(pResponse);
		endif;
		responseWriteJson(pResponse);
	endif;

end-proc;
// -------------------------------------------------------------------- 
// JSON error monitor 
// -------------------------------------------------------------------- 
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
// -------------------------------------------------------------------- 
// JSON - success response 
// --------------------------------------------------------------------
dcl-proc successTrue export;

	dcl-pi *n pointer;
	end-pi;                     

	return json_parseString ('{"success": true}');

end-proc;
**free
//<%@ language="RPGLE" pgmopt="BNDSRVPGM((STATPROD))"%>
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('NOXDB':'ICEUTILITY');

/* -----------------------------------------------------------------------------
   Service . . . : microservice - 
   Author  . . . : Niels Liisberg 
   Company . . . : System & Method A/S
  
   Static router. Alternative to the dynamic router in router.rpgle
   Here the service program and procedure is static bound. 
   but you can use the same service program and just change the procedure to call based on the URL path.

   Note: we need a binding directory - and export procedure - this is 
   similar to "normal" RPGLE service program but with the export procedure.

   here we use the pgmopt="BNDSRVPGM((STATPROD))" on the compile optoin 
   to bind the service program, but you can of course also 
   use a binding directory and bind it there.

   CRTICEPGM STMF('/www/IceBreak-Samples/statRoute.rpgle') SVRID(samples)
   
   By     Date       PTF     Description
   ------ ---------- ------- ---------------------------------------------------
   NLI    04.03.2026         New program
   ----------------------------------------------------------------------------- */
 /include qrpgleref,jsonparser
 /include qrpgleref,iceutility
 
// --------------------------------------------------------------------
// Main line:
// --------------------------------------------------------------------
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
   get payload data form request and build JSON graph
   note: for production use HTTP POST with JSON payload in body
   not the URL GET parameter ?payload= but this is ok for testing
\* -------------------------------------------------------------------- */
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
/* -------------------------------------------------------------------- *\ 
   	run a JSON-in/JSON-out service. but also handles 
	"classic" calls into any program or service program 

	the "runService" procedure is the heart of the router, 
	it takes care of calling the right service program and 
	procedure based on the URL path and the input payload.

	This part is the only different part in the static router 
	compared to the dynamic router in router.rpgle, where we 
	load the service program and procedure dynamically based on the URL path.

\* -------------------------------------------------------------------- */
dcl-proc runService export;	

	dcl-pi *n pointer;
		pPayload pointer value;
	end-pi;

	// For simplicity we can put the prototypes for the service program procedures here 
	// but you can of course put them in a copybook 
	dcl-pr statprod_simple pointer extproc('SIMPLE');
		pJsonInput 			pointer value;
	end-pr;

	// When you use static binding you can of course just call the procedure directly without the need for the extproc prototype and loadServiceProgramProc
	// that giesves you the fredom to use any parameter style you like 
	// and make it perfect RPGLE with the right data types and parameters instead of just JSON in and JSON out. 
	dcl-pr statprod_classic extproc('CLASSIC');
		myInput  pointer;
		myOutput pointer;
		whatever varchar(128) const;
	end-pr;

	dcl-pr statprod_classicRLA extproc('CLASSICRLA');
		myInput  pointer;
		myOutput pointer;
		whatever varchar(128) const;
	end-pr;

	dcl-s pResponse		pointer;		
	dcl-s action  		varchar(128);
	dcl-s pgmName 		char(10);
	dcl-s procName 		varchar(128);
	dcl-s errText  		char(128);
	dcl-s errPgm   		char(64);
	dcl-s errList 		char(4096);
  	dcl-s len 			int(10);

	// Get the action from the request URL
	// Example: /router/mySrvPgm/myProcedure 
	// gives mySrvPgm as service program and myProcedure as procedure
	// Note: in this static router example we will not load the service program and procedure dynamically
	// but just use the URL to decide which procedure to call.
	action = strUpper(getServerVar('REQUEST_FULL_PATH'));
	len = words(action:'/');
	pgmName  = word (action:len-1:'/');
	procName = word (action:len:'/');

	monitor;
		select;

			// JSON in / JSON out procedure
			when pgmName = 'STATPROD' and procName = 'SIMPLE';
				pResponse =  statprod_simple(pPayload); 

			// We can prepare the response JSON object before calling the classic RPGLE procedure 
			// and pass it as a parameter, so the procedure can fill it with data and status.
			when pgmName = 'STATPROD' and procName = 'CLASSIC';
				pResponse = json_newObject(); 
				json_setStr(pResponse : 'someStuff' : 'What ever');
				
				json_moveObjectInto(pResponse : 'parse' : 
					json_parseString('{"inputFromRequest": "This is some input data from the request that we move into the response as an example of how to pass data into the classic RPGLE procedure"}')
				); // move the request into the output parameter as an "eye-catcher"

				statprod_classic(
					pPayload : 
					pResponse : 
					'Hello, World!'
				);

			// Here we let the classic RPGLE procedure prepare the whole response, 
			// so we just pass an null pointer and let the procedure fill it with data and status.
			when pgmName = 'STATPROD' and procName = 'CLASSICRLA';
				statprod_classicRLA(
					pPayload : 
					pResponse : 
					'Hello, World!'
				);
			other;
				pResponse = formatError('Unknown service program in URL: ' + action); 
		endsl;

	on-error;                                     
		soap_Fault(errText:errPgm:errList);    
		pResponse = formatError (
			'Error in service ' + action + ', ' + errText
		);
	endmon;                                       	

	return pResponse; 

end-proc;
/* -------------------------------------------------------------------- *\  
   send response to client	
\* -------------------------------------------------------------------- */
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
   JSON - success response 
\* -------------------------------------------------------------------- */
dcl-proc successTrue export;

	dcl-pi *n pointer;
	end-pi;                     

	return json_parseString ('{"success": true}');

end-proc;

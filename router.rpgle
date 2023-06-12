<%@ language="RPGLE" runasowner="*YES" owner="QPGMR"%>
<%
ctl-opt copyright('System & Method (C), 2019');
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
   ----------------------------------------------------------------------------- */
 /include qasphdr,jsonparser
 /include qasphdr,iceutility
 
// --------------------------------------------------------------------
// Main line:
// --------------------------------------------------------------------
dcl-proc main;

	dcl-s pPayload       pointer;

	pPayload = unpackParms();
	if json_nodeType(pPayload) = JSON_ARRAY;
		processTransactions(pPayload);
	else;
		processAction(pPayload);
	endif;
	cleanup(pPayload);
	return;

end-proc;
// --------------------------------------------------------------------  
dcl-proc processTransactions;

	dcl-pi *n;
		pPayload pointer value;
	end-pi;

	dcl-ds iterTrans  	likeds(json_iterator);
	dcl-s  pAction 		pointer;

	// Transactions are transfered in chunks - and flushed pr. tranasaction type
	// to let the undelying transaction provide have a clean response to work with.
	// ( Chuncks are not used generic since export breaks )
	setChunked(4096);

	%>[<%
	iterTrans = json_SetIterator(pPayload);
	dow json_ForEach(iterTrans);
		responseWrite(iterTrans.comma);
		// pAction = json_nodeUnlink(iterTrans.this);
		processAction(iterTrans.this);
		// json_delete(pAction);
		// flush each "chunk"
		responseFlush();
	enddo;
	%>]<%

end-proc;
// --------------------------------------------------------------------  
dcl-proc processAction;	

	dcl-pi *n;
		pAction pointer value;
	end-pi;
	
	dcl-s pResponse		pointer;		

	pResponse = runService (pAction);
	if (pResponse = *NULL);
		responseWrite('null');
	else;
		responseWriteJson(pResponse);
		if json_getstr(pResponse : 'success') = 'false';
			setStatus ('500 ' + json_getstr(pResponse: 'message'));
			consoleLogjson(pResponse);
		endif;
		json_close(pResponse);
	endif;

end-proc;
/* -------------------------------------------------------------------- *\  
   get data form request
\* -------------------------------------------------------------------- */
dcl-proc unpackParms;

	dcl-pi *n pointer;
	end-pi;

	dcl-s pPayload 		pointer;
	dcl-s msg     		varchar(4096);
	dcl-s callback     	varchar(512);


	SetContentType('application/json; charset=utf-8');
	SetEncodingType('*JSON');
	json_setDelimiters('/\@[] ');
	json_sqlSetOptions('{'             + // use dfault connection
		'upperCaseColname: false,   '  + // set option for uppcase of columns names
		'autoParseContent: true,    '  + // auto parse columns predicted to have JSON or XML contents
		'sqlNaming       : false    '  + // use the SQL naming for database.table  or database/table
	'}');

	callback = reqStr('callback');
	if (callback>'');
		responseWrite (callback + '(');
	endif;

	if reqStr('payload') > '';
		pPayload = json_ParseString(reqStr('payload'));
	elseif getServerVar('REQUEST_METHOD') = 'POST';
		pPayload = json_ParseRequest();
		if pPayload = *NULL;
			pPayload = json_newObject(); // just an empty object;
		endif;
	else;
		pPayload = *NULL;
	endif;

	if pPayload = *NULL;
		msg = json_message(pPayload);
		%>{ "text": "Microservices. Ready for transactions. Please POST payload in JSON", "desc": "<%= msg %>"}<%
		return *NULL;
	endif;

	return pPayload;


end-proc;
// -------------------------------------------------------------------------------------
dcl-proc cleanup;
	
	dcl-pi *n;
		pPayload pointer value;
	end-pi;
	dcl-s callback     	varchar(512);

	json_close(pPayload);

	callback = reqStr('callback');
	if (callback > '');
		responseWrite (')');
	endif;

end-proc;
/* -------------------------------------------------------------------- *\ 
   	run a a microservice call
\* -------------------------------------------------------------------- */
dcl-proc runService export;	

	dcl-pi *n pointer;
		pActionIn pointer value options (*string);
	end-pi;

	dcl-pr ActionProc pointer extproc(pProc);
		payload pointer value;
	end-pr;
	
	dcl-s Action  		varchar(128);
	dcl-s prevAction  	varchar(128) static;
	dcl-s pgmName 		char(10);
	dcl-s procName 		varchar(128);
	dcl-s pProc			pointer (*PROC) static;
	dcl-s pAction       pointer;
	dcl-s pResponse		pointer;		
	dcl-s errText  		char(128);
	dcl-s errPgm   		char(64);
	dcl-s errList 		char(4096);
  dcl-s len 			int(10);


// will return the same pointer id action is already a parse object
	pAction = json_parseString(pActionIn);

	action   = json_GetStr(pAction:'action');
	if (action <= '');
		action = strUpper(getServerVar('REQUEST_FULL_PATH'));
		len = words(action:'/');
		pgmName  = word (action:len-1:'/');
		procName = word (action:len:'/');
	else;

		//if  action <> prevAction;
		//	prevAction = action;
		action = strUpper(action);
		pgmName  = word (action:1:'.');
		procName = word (action:2:'.');
	endif;

	//if  action <> prevAction;
	//	prevAction = action;
	pProc = loadServiceProgramProc ('*LIBL': pgmName : procName);
	//endif;

	if (pProc = *NULL);
		pResponse= FormatError (
			'Invalid action: ' + action + ' or service not found'
		);
	else;
		monitor;

		pResponse = ActionProc(pAction);

		on-error;                                     
			soap_Fault(errText:errPgm:errList);    
			pResponse =  FormatError (
				'Error in service ' + action + ', ' + errText
			);
		endmon;                                       	

	endif;

	// if my input was a jsonstring, i did the parse and i have to cleanup
	if pAction <> pActionIn;
		json_delete (pAction);
	endif;

	return pResponse; 

end-proc;

/* -------------------------------------------------------------------- *\ 
   JSON error monitor 
\* -------------------------------------------------------------------- */
dcl-proc FormatError export;

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

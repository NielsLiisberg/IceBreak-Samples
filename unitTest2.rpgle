<%@ language="RPGLE" runasowner="*YES" owner="QPGMR"%>
<%
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('NOXDB':'ICEUTILITY':'QC2LE');

/* -----------------------------------------------------------------------------
   Service . . . : microservice router
   Author  . . . : Niels Liisberg 
   Company . . . : System & Method A/S
  
   CRTICEPGM STMF('/www/IceBreak-Samples/unittest2.rpgle') SVRID(samples)
   
   By     Date       PTF     Description
   ------ ---------- ------- ---------------------------------------------------
   NLI    10.05.2018         New program
   ----------------------------------------------------------------------------- */
 /include noxdb 
 /include qasphdr,iceutility
 
// --------------------------------------------------------------------
// Main line:
// --------------------------------------------------------------------
dcl-proc main;

	dcl-s pInput        pointer;
	dcl-s pOutput       pointer;
    dcl-s errCount      int(10);
	dcl-s msg           varchar(256);
 
	pInput = json_parseString ('{      -
		"action": "msXlate.translate", -
		"source": "en", -
		"target": "es", -
		"text"  : "Good afternoon my friends" -
	}');

	pOutput = runService (pInput);

    // required output:
	msg = json_getStr(pOutput : 'translations[0].translation');
	logText(msg);

	json_delete(pInput);
	json_delete(pOutput);

end-proc;
/* -------------------------------------------------------------------- *\ 
   	log if problems
\* -------------------------------------------------------------------- */
dcl-proc fail ;	

	dcl-pi *n;
        errCount int(10);
        text varchar(256) value;
        pIn pointer value; 
        pOut pointer value;
	end-pi;

    errCount += 1;

    logText ('Error in' + text);
    logJson  (pIn);
    logJson (pOut);

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

	// will return the same pointer id action is already a parse object
	pAction = json_parseString(pActionIn);

	action   = strUpper(json_GetStr(pAction:'action'));
	
	//if  action <> prevAction;
	//	prevAction = action;
	pgmName  = word (action:1:'.');
	procName = word (action:2:'.');
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

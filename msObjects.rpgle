**free
//<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain;
ctl-opt option(*nodebugio:*srcstmt:*nounref);
ctl-opt bndDir('NOXDB':'ICEUTILITY' );
// -----------------------------------------------------------------------------
//
//  CRTICEPGM STMF('/www/IceBreak-Samples/msObjects.rpgle') SVRID(samples)
//
//
//  By     Date       PTF     Description
//  ------ ---------- ------- ---------------------------------------------------
//  NLI    22.06.2019         New program
//  NLI	   15.11.2022         Refactored for noxDB JSON features
//  NLI	   26.01.2026         Gracefull error + cleanup 
//  -----------------------------------------------------------------------------
 /include qrpgleref,jsonParser
 /include qrpgleref,iceUtility

// -----------------------------------------------------------------------------  
//  return a resulset from the SQL select 
//
//	use the the IceBreak sandbox at "sandbox.icebreak.org"
//	or configure your host table to have MY_IBM_I
//
//	Note the "payload" parameter on the URL is a IceBreak shortcut 
//	for a HTTP POST with the same payload.
//	Only use the HTTP GET .. ?payload for test and debugging. Never in production.  
//
//	Rest style
//	http://MY_IBM_I:60060/router/msObjects/programs?payload={"library":"SAMPLES"}
//	
// -------------------------------------------------------------------------------
**free

// POST /router/msObjects/programs  {"library":"MYAPP"}  ->  the programs of the library
dcl-proc programs export;
	dcl-pi *n pointer;
		input pointer value;
	end-pi;
	dcl-s parms pointer;
	dcl-s rows pointer;

	parms = json_newObject();
	json_setStr(parms : 'library' : %upper(json_getStr(input : 'library' : 'QGPL')));
	rows = json_sqlResultSet(
		'select objname, objtype, objtext, last_used_timestamp ' +
		'from table(qsys2.object_statistics(${library}, ''*PGM *SRVPGM'')) ' +
		'order by objname' :
		1 : 500 : JSON_META + JSON_GRACEFUL_ERROR : parms);
	json_delete(parms);
	return rows;
end-proc;
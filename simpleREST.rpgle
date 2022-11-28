<%@ language="RPGLE" %>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 

/*  -----------------------------------------------------------------------------


	Simple REST  - showcase that injection is not possible

  	A list of product prduced by a given manufacturer
	   
	Run from the browser:

	http://sandbox.icebreak.org:60060/simpleRest?manuid=SONY
	http://my_ibm_i:60060/simpleRest?manuid=SONY


	Compile:
	CRTICEPGM STMF('/www/IceBreak-Samples/simpleREST.rpgle') SVRID(samples)


	By     Date       PTF     Description
	------ ---------- ------- ---------------------------------------------------
	NLI    22.06.2019         New program
	----------------------------------------------------------------------------- */
 /include noxDB
 /include qasphdr,iceUtility
 
dcl-proc main;

	dcl-s  manuId       varchar(30);
	dcl-s  sqlStr       varchar(1024);
	dcl-s  pResult      pointer;

	// We will produce JSON in UTF-8 format
	setContentType('application/json;charset=UTF-8');

	// Get the manufaturer from the query string or the form
	manuId = reqStr('manuId'); 

	// Create the dynamic sql statement 
	// Note:  strQuot to protect agains SQL-injections
	sqlStr = (`
		select * 
		from icproduct 
		where manuId = ${ strQuot(manuId)}
		order by Desc
	`);

	// run the sql and return a JSON object graph in memory
	pResult = json_sqlResultSet (
		sqlStr
	);

	// serializet it to the client and dispose memory
	responseWriteJson(pResult);
	json_delete(pResult);


end-proc;
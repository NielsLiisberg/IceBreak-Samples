<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/msSimple.rpgle') SVRID(samples)


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2019         New program
  ----------------------------------------------------------------------------- */
 /include noxDB
 /include qasphdr,iceUtility


/* -------------------------------------------------------------------- *\ 
   	The mother of all samples: hellow world
	   
	http://my_ibm_i:60060/router/msSimple/Hello?payload={
		"message":"My name is John"
	}

\* -------------------------------------------------------------------- */
dcl-proc HelloWim export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s  pOutput   	pointer;


	pOutput = json_newObject();

	json_setStr  (pOutput: 'text' : 'Hello world ');
	json_setDate (pOutput: 'date' : %date());
	json_setTime (pOutput: 'time' : %time());
	json_setStr  (pOutput: 'message' : json_getStr(pInput : 'message'));
	
	return pOutput;

end-proc;
/* -------------------------------------------------------------------- *\ 
   	returns sum of x and y

	http://my_ibm_i:60060/router?payload={
		"action":"msSimple.sum",
		"x": 123,
		"y": 456
	}

\* -------------------------------------------------------------------- */
dcl-proc sum export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pOutput      	pointer;
	dcl-s  x      			int(10);
	dcl-s  y      			int(10);


	x = json_getnum(pInput : 'x');
	y = json_getnum(pInput : 'y');

	pOutput = json_newObject();
	json_setInt(pOutput : 'sum' : x + y);

	return pOutput;

end-proc;
/* -------------------------------------------------------------------- *\ 
   	division - can it handle divide by zero? 

	http://my_ibm_i:60060/router/msSimple/divide?payload={
		"x": 125,
		"y": 10
	}

\* -------------------------------------------------------------------- */
dcl-proc divide export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pOutput      	pointer;
	dcl-s  x      			int(10);
	dcl-s  y      			int(10);


	x = json_getnum(pInput : 'x');
	y = json_getnum(pInput : 'y');

	pOutput = json_newObject();
	json_setInt(pOutput : 'divide' : x / y);

	return pOutput;

end-proc;
/* -------------------------------------------------------------------- *\ 
   	List products


	http://my_ibm_i:60060/router/msSimple/products?payload={}


\* -------------------------------------------------------------------- */
dcl-proc products export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pResultSet     	pointer;
	dcl-s  sqlStmt        	varchar(4096);

   
	sqlStmt = (`
		select * 
		from icproduct
	`);

	pResultSet = json_sqlResultSet   (
		sqlStmt
		: 1
		: 5
		: JSON_META + JSON_TOTALROWS
	);


	return pResultSet;

end-proc;




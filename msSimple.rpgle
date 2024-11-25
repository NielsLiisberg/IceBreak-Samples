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
	   
   	note the "action" can be either from the URL or by a selfcontained message:

	http://sandbox.icebreak.org:60060/router?payload={
		"action":"msSimple.Hello",
		"message" : "My name is John"
	}

	or by url:

	http://my_ibm_i:60060/router/msSimple/Hello?payload={
		"message" : "My name is John"
	}

\* -------------------------------------------------------------------- */
dcl-proc Hello export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s  pOutput   	pointer;


	pOutput = json_newObject();

	json_setStr(pOutput: 'text' : 'Hello world ');
	json_setStr(pOutput: 'time' : %char(%timestamp()));
	json_setStr(pOutput: 'message' : json_getStr(pInput : 'message'));
	
	return pOutput;

end-proc;
// --------------------------------------------------------------------
/** 
   	Convert any positive integer to packed decimal for the command 
   	processor. The input can be int,packed, zoned, float.

   	@parm  input 	any positive interger value
	@parm  packLen 	any uneven number: 1, 3, 5, 7, 9, ...
	@return 		string in format:  x'0012345F' for strPack(12345:7)
   	
*/
// --------------------------------------------------------------------
dcl-proc strPack; 

	dcl-pi *n varchar(32);
		input 			int(20) value;
		packlen  		int(5) value;
	end-pi;

	dcl-s	temp 		varchar(32);

	temp = %char(1000000000000000000 + input);
	temp = %subst(temp:%len(temp)-packLen+1);
	temp = 'x''' + temp + 'F''';

	return temp;

end-proc;


/* -------------------------------------------------------------------- *\ 
   	returns sum of x and y

	http://sandbox.icebreak.org:60060/router?payload={
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

	http://sandbox.icebreak.org:60060/router?payload={
		"action":"msSimple.divide",
		"x": 125,
		"y": 5
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

	http://sandbox.icebreak.org:60060/router?payload={
		"action":"msSimple.products"
	}

\* -------------------------------------------------------------------- */
dcl-proc products export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pResultSet     	pointer;
	dcl-s  sqlStmt        	varchar(4096);

   
	sqlStmt = (`
		select * 
		from product
	`);

	pResultSet = json_sqlResultSet   (
		sqlStmt
		: 1
		: 2000
		: JSON_META + JSON_TOTALROWS
	);


	return pResultSet;

end-proc;




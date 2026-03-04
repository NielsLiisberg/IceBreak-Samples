**free
//<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
ctl-opt copyright('System & Method (C), 2019-2022');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
// ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/statProd.rpgle') SVRID(samples)

  CRTSRVPGM SRVPGM(SAMPLES/STATPROD)    
          MODULE(SAMPLES/STATPROD)    
          EXPORT(*ALL)                
          BNDSRVPGM((NOXDB/JSONXML))  


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2019         New program
  NLI	 15.11.2022         Refactored for noxDB JSON features
  NLI	 26.01.2026         Gracefull error + cleanup 
  ----------------------------------------------------------------------------- */
 /include noxDB
 /include qrpgleref,iceUtility

	dcl-f listFile  
		extdesc('ICPRODUCT') 
		keyed 
		usage(*input)
		extfile(*extdesc) 
		rename(PRODUCTR:listRec)
		usropn;

/* -------------------------------------------------------------------- *\ 
   	return a resulset from the SQL select 

	use the the IceBreak sandbox at "sandbox.icebreak.org"
	or configure your host table to have MY_IBM_I

	Note the "payload" parameter on the URL is a IceBreak shortcut 
	for a HTTP POST with the same payload.
	Only use the HTTP GET .. ?payload for test and debugging. Never in production.  

	// Rest style
	http://MY_IBM_I:60060/statRoute/statProd/simple

	
\* -------------------------------------------------------------------- */
dcl-proc simple export;

	dcl-pi *n pointer;
		pJsonInput 			pointer value;
	end-pi;

	dcl-s  pJsonOutput     	pointer;
    
    pJsonOutput = json_sqlResultSet('-
		select *         -
		from icproduct    -
	');

	return pJsonOutput;

end-proc;

/* -------------------------------------------------------------------- *\ 
   	return a resulset from the SQL select 

	use the the IceBreak sandbox at "sandbox.icebreak.org"
	or configure your host table to have MY_IBM_I

	Note the "payload" parameter on the URL is a IceBreak shortcut 
	for a HTTP POST with the same payload.
	Only use the HTTP GET .. ?payload for test and debugging. Never in production.  

	// Rest style
	http://MY_IBM_I:60060/statRoute/statProd/classic

	The same as simple but with classic RPGLE parameters passed by reference instead of JSON in and JSON out. 
	This is to show that you can use any parameter style you like when you use static binding, and not just JSON in and JSON out. 
	Of course you can also use the JSON in and JSON out style if you like, but this gives you the freedom to use the right data 
	types and parameters for your procedure instead of just JSON in and JSON out.
\* -------------------------------------------------------------------- */
dcl-proc classic export;

	dcl-pi *n;
		myInput  pointer;
		myOutput pointer;
		whatever varchar(128) const;
	end-pi;

	dcl-s  pRows      pointer;

    pRows  = json_sqlResultSet('-
		select *         -
		from icproduct    -
	');

	json_setStr(myOutput : 'someStuff' : whatever);
	json_moveObjectInto(myOutput : 'request' : myInput); // move the request into the output parameter as an "eye-catcher"
	json_moveObjectInto(myOutput : 'rows' : pRows); // move the request into the output parameter as an "eye-catcher"

end-proc;
/* -------------------------------------------------------------------- *\ 
   	return a resulset from the SQL select 

	here we use record level acces RLA - what ever you like, you are not "limted" to SQL.
	
	// Rest style
	http://MY_IBM_I:60060/statRoute/statProd/classicrla

	The same as classic but here we let the procedure prepare the whole response, so we just pass an null pointer and let the procedure fill it with data and status.
\* -------------------------------------------------------------------- */
dcl-proc classicrla export;


	dcl-pi *n;
		myInput  pointer;
		myOutput pointer;
		whatever varchar(128) const;
	end-pi;

	dcl-s  pRow       pointer;
	dcl-s  pRows      pointer;


	myOutput = json_newObject(); // just an empty object to be filled by the procedure and returned to the caller.

	pRows = json_newArray(); // create a new JSON array to hold the rows of the result set
	open listFile;
	setll *loval listRec;
	read listRec;  
	dow (not %eof(listFile) ) ; 
		pRow = json_newObject(); // create a new JSON object for the current record
		json_setStr ( pRow : 'prodId' : prodId); // add the
		json_setStr ( pRow : 'description' : desc); // add the
		json_arrayPush (pRows : pRow); // push the current record object into the rows array
		read listRec;  
	enddo;
	close listFile;

	json_setStr(myOutput : 'someStuff' : whatever);
	json_moveObjectInto(myOutput : 'request' : myInput); // move the request into the output parameter as an "eye-catcher"
	json_moveObjectInto(myOutput : 'rows' : pRows); // move the request into the output parameter as an "eye-catcher"

end-proc;

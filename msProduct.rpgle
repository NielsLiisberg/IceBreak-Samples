<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2019-2022');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/msProduct.rpgle') SVRID(samples)


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2019         New program
  ----------------------------------------------------------------------------- */
 /include noxDB
 /include qasphdr,iceUtility

/* -------------------------------------------------------------------- *\ 
   	return a resulset from the SQL select 

	use the the IceBreak sandbox at "sandbox.icebreak.org"
	or configure your host table to have MY_IBM_I

	Note the "payload" parameter on the URL is a IceBreak shortcut 
	for a HTTP POST with the same payload.
	Only use the HTTP GET .. ?payload for test and debugging. Never in production.  

	// Rest style
	http://MY_IBM_I:60060/router/msProduct/simple?payload={}

	
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
	http://MY_IBM_I:60060/router/msProduct/getRows?payload={
		"start": 11,
		"limit": 20,
		"search" : "sony"
	}

	// "seneca" style
	http://MY_IBM_I:60060/router?payload={
		"action":"msProduct.getRows",
		"start": 11,
		"limit": 20,
		"search" : "sony"
	}

	// "seneca" style
	http://MY_IBM_I:60060/router?payload={
		"action":"msProduct.getRows",
		"start": 11,
		"limit": 20,
		"where" : "price > 200",
		"sort"  : "price"
	}
\* -------------------------------------------------------------------- */
dcl-proc getRows export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pResultSet     	pointer;
	dcl-s  sqlStmt        	varchar(4096);
	dcl-s  search 	   		varchar(4096);
	dcl-s  start  			int(10);
	dcl-s  limit  			int(10);
 

	search  =  json_getStr(pInput : 'search');
	start   =  json_getNum(pInput : 'start' );
	limit   =  json_getNum(pInput : 'limit' );

	sqlStmt = (`
		select * 
		from icproduct
	`);

	addWhereClause   ( sqlStmt : pInput);
	addOrderByClause ( sqlStmt : pInput);

	pResultSet = json_sqlResultSet   (
		sqlStmt
		: start + 1
		: limit
		: JSON_META + JSON_TOTALROWS
	);


	return pResultSet;

end-proc;
/* -------------------------------------------------------------------- *\
   Normal proccedure for adding the " order by " clause to the sql 
\* -------------------------------------------------------------------- */
dcl-proc addOrderByClause;

	dcl-pi *N;
		sqlStmt             varchar(4096); 
		pInput 				pointer value;
	end-pi;

	dcl-s  sort  	   		varchar(4096);

	sort    =  json_getStr(pInput : 'sort');

	// Concat the order by:
	if sort > '';
		sqlStmt += ' order by ' + sort;
	endif; 


end-proc;
/* -------------------------------------------------------------------- *\
   Normal proccedure for adding the " order by " clause to the sql 
\* -------------------------------------------------------------------- */
dcl-proc addWhereClause;

	dcl-pi *n;
		sqlStmt             varchar(4096); 
		pInput 				pointer value;
	end-pi;

	dcl-ds itColumns        likeds(json_iterator);
	dcl-s  search 	   		varchar(256);
	dcl-s  where  	   		varchar(4096);
	dcl-s  pMeta 			pointer;
	dcl-s  flds 			varchar(4096);

	search =  json_getStr(pInput : 'search');
	where  =  json_getStr(pInput : 'where');

	// When the client has a "where" we simply use that 
	// In production - tak care !! this might be prone to "SQL injections"
  	if where > '';
		sqlStmt += ' where ' + where;
	elseif search  > '';
		pMeta = getMetadata(*NULL);
		itColumns = json_setIterator(pMeta);
		dow json_forEach(itColumns);
			strAppend ( 
				flds 
				: ' concat ' 
				: 'char(' + json_getStr(itColumns.this:'name') + ')'
			);
		enddo;
		json_delete(pMeta);

		sqlStmt += ' where lower(' + flds + ') like ' 
			+ lowercase(strQuot('%' + search+ '%'));
	endif;

end-proc;
/* -------------------------------------------------------------------- *\
   update row 
\* -------------------------------------------------------------------- */
dcl-proc update export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s err			ind;
	dcl-s pOutput		pointer;
	dcl-s pRow			pointer;

	// asume ok;
	pOutput = json_parseString('{success:true}');

	// Find the sql rodata within my input
	pRow = json_locate (pInput : 'row');

	ensureKey (pRow);

	// update using object as the row 
	// Note: we can use templates for the key                                             
	err = json_sqlUpsert (                                                        
		'icproduct'                	  // table name                                     
		:pRow                  	      // row in object form {a:1,b:2} etc..             
		:'where prodkey = $prodkey'   // Where clause ( you can omit the "where" )      
		:pRow                         // object containing the key              
	);                                                                            	

	if err;
		json_setBool (pOutput : 'success' : *OFF);
		json_setStr  (pOutput : 'msg'    : json_Message(*NULL));
	endif;

	return pOutput;

end-proc;
/* -------------------------------------------------------------------- *\
   if the key is null, it is a insert operation
   then find the next key 
\* -------------------------------------------------------------------- */
dcl-proc ensureKey;

	dcl-pi *n;
		pInput 			pointer value;
	end-pi;

	dcl-s pTemp			pointer;

	// If no key is supplied, then create a new one, in steps +10 
	if json_getNum ( pInput : 'prodkey') =0;
		pTemp = json_sqlResultRow ('-  
			select max(prodkey) + 10  as prodkey-
			from icproduct -
		');
		json_copyvalue (pInput: 'prodkey' : pTemp: 'prodkey');
		json_delete (pTemp);
	endif;

end-proc;
/* -------------------------------------------------------------------- *\
   delete row 
\* -------------------------------------------------------------------- */
dcl-proc delete export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s err			ind;
	dcl-s pOutput		pointer;
	
	// asume ok;
	pOutput = json_parseString('{success:true}');

	// delete using input object as the template data
	err = json_sqlExec (                                                        
		'Delete from icproduct where prodkey = $key'   // Where clause ( you can omit the "where" )      
		:pInput                                      // object containing the key              
	);                                                                            	

	if err;
		json_setBool (pOutput : 'success' : *OFF);
		json_setStr  (pOutput : 'msg'    : json_Message(*NULL));
	endif;

	return pOutput;

end-proc;

/* -------------------------------------------------------------------- *\ 
   	Get the table metadata: columns and types

	http://sandbox.icebreak.org:60060/router?payload={
		"action":"msProduct.getMetadata"
	}

\* -------------------------------------------------------------------- */
dcl-proc getMetadata export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s  pMeta      	pointer;
	dcl-s  pKey			pointer;  

	
	pMeta = json_sqlGetMeta  ('-
		select * - 
		from icproduct -
	');

	// Add which column is the primary key
	pKey = json_locate (pMeta : '[name=prodkey]'); 
	json_setBool (pKey : 'isIdColumn' : *ON);

	return pMeta;

end-proc;



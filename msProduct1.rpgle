<%@ language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2016');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 

/*  -----------------------------------------------------------------------------

    Simple microservices - showcase that injection is not possible


    CRTICEPGM STMF('/www/IceBreak-Samples/msProduct1.rpgle') SVRID(samples)


    By     Date       PTF     Description
    ------ ---------- ------- ---------------------------------------------------
    NLI    22.06.2016         New program
    ----------------------------------------------------------------------------- */
 /include noxDB
 /include qasphdr,iceUtility
 

/* -------------------------------------------------------------------- *\ 
   	A list of product prduced by a given manufacturer
       
   	note the "action" can be either from the URL or by a selfcontained message:

	dksrv206:60060/router?payload={
		"action":"msProduct1.productList",
		"manuId" : "ACER"
	}

    or url:

    dksrv206:60060/router/msProduct1/productList?payload={
		"manuId" : "ACER"
	}



\* -------------------------------------------------------------------- */
dcl-proc productList export;

	dcl-pi *n pointer;
		pInput 			pointer value;
	end-pi;

	dcl-s  pOutput   	pointer;
    dcl-s  sqlStr       varchar(4096);
    dcl-s  manuId       varchar(30);
    
    k = 123; 

    manuId = strQuot(json_getStr(pInput:'manuId')); 

    sqlStr = (`
        select * 
        from product 
        where manuId = ${ manuId}
        order by Desc
    `);

    pOutput = json_sqlResultSet (
        sqlStr
    );

    return pOutput;


end-proc;

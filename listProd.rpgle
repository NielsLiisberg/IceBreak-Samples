<%@ language="SQLRPGLE" " %>
<%
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0.') datEdit(*YMD.) main(produceList); 
ctl-opt bndDir('ICEBREAK');
exec sql set option commit=*NONE;
/* -----------------------------------------------------------------------------

	CRTICEPGM STMF('/www/IceBreak-Samples/listProd.rpgle') SVRID(samples)

   	Send a product list to a client
	   
	dksrv206:60060/listProd.rpgle?search=silver
	
\* -------------------------------------------------------------------- */
dcl-proc produceList;

	dcl-s  search       varchar(256);
	dcl-s  comma        varchar(1);
	dcl-ds product      extname ('PRODUCT') qualified end-ds;
	
  
	// we are providing JSON for the client
	setContentType('application/json;charset=utf-8');
	
	// Get the data from the URL
	search = '%' + qryStr('search') + '%';

	exec sql declare c1 cursor for
		select * 
		from product
		where lower(desc) like lower (:search);

	exec sql open c1;

	%>[<%
	exec sql fetch c1 into :product;
	dow sqlCode =  0;
		%><%=comma %>
		{
			"prodkey": <% = %char(product.prodKey) %>,
			"prodid": "<% = product.prodid  %>",
			"desc": "<% = product.desc %>",
			"manuid": "<%=  product.manuid %>",
			"price": <%= %char(product.price) %>,
			"stockcnt": <%= %char(product.stockcnt) %>,
			"stockdate": "<%= %char(product.stockdate) %>"
		}<%
		comma = ',';
		exec sql fetch c1 into :product;
	enddo;
	exec sql close c1;
	%>]<%

end-proc;

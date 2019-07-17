<%@ free="*YES"%>
<%
/* -------------------------------------------------------------------------------- *\

	Public test:

    http://portfolio.icebreak.org/samples/web1dot0.rpgle
    
\* -------------------------------------------------------------------------------- */
ctl-opt decEdit(*jobrun) datEdit(*YMD) main(main); 
ctl-opt bndDir('ICEBREAK');

dcl-f updFile  
	extdesc('PRODUCT') 
	extfile(*extdesc) 
	usage(*input : *update: *output : *delete)
	rename(PRODUCTR:updRec);

dcl-f listFile  
	disk(*ext) 
	extdesc('PRODUCT') 
	keyed 
	infds(InfoDS) 
	usage(*input)
	extfile(*extdesc) 
	rename(PRODUCTR:listRec);

dcl-ds infoDS; 
	rrn int(10) pos(397);
end-ds;

// --------------------------------------------------------------------------------
// The Main logic controling the state from previous incarnations
// --------------------------------------------------------------------------------
dcl-proc Main;

	// Previous function parses update or add parameter
	// ------------------------------------------------
	select;
			 
		// The "New" button is clicked in the inputForm form
		when reqStr('Option') = 'New' ; 
			rrn = 0;
			clear updRec;
			inputForm ();

		// The "Update" button is clicked in the inputForm form. Update or write new record
		when reqStr('Option') = 'Update'; 
			rrn = reqNum('sys.rrn');
			if (rrn = 0) ;
				form2db();
				write updRec;
			else;
				chain rrn updRec;
				Form2db();
				update updRec;
			endif;
			loadList();  

		// The "Delete" button is clicked - and a rrn exists; now delete that record
		when reqStr('Option') = 'Delete'; 
			rrn = reqNum('sys.rrn');
			if rrn > 0;
				chain rrn updRec;
				delete updrec; 
			endif;
			loadList();  


		// Return without update - just reload the list
		when reqStr('Option') = 'Return' ;
			loadList();  

		// When Clicking on a row in the table the " href .." returns the "rrn" allong in the "QryStr"
		when reqNum('rrn') > 0; 
			rrn = QryStrNum('rrn');
			chain rrn updRec;
			setll *hival updRec;
			inputForm();
		other;
			loadList();  
	endsl;

End-proc;
// ------------------------------------------------------------------ *
// Form to database for product   
// ------------------------------------------------------------------ *
dcl-proc Form2db;

	PRODKEY    = reqNum('PRODKEY'); // Product Key
	PRODID     = reqStr('PRODID'); // Product ID
	DESC       = reqStr('DESC'); // Description
	MANUID     = reqStr('MANUID'); // Manufacturer ID
	PRICE      = reqNum('PRICE'); // Price
	STOCKCNT   = reqNum('STOCKCNT'); // Stock Count
	STOCKDATE  = %date(reqStr('STOCKDATE')); // Stock Date

end-proc;
// --------------------------------------------------------------------------------
// Setup the HTML header and stylesheet / (evt. the script links)
// --------------------------------------------------------------------------------
dcl-proc head;
%><html>
 <Head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<link rel="stylesheet" type="text/css" href="/System/Styles/portfolio.css"/>
 </head> 
 <body>
 <h1>Product master</h1>
<%
end-proc;
// --------------------------------------------------------------------------------
// Finish up the final html
// --------------------------------------------------------------------------------
dcl-proc tail;
%></body>
</html>
<%
end-Proc;

// --------------------------------------------------------------------------------
// loadList; is much like a "load subfile". All records are placed into a html table
// --------------------------------------------------------------------------------
dcl-proc loadList;
	dcl-s i         int(10);
	dcl-s urlManuId varchar(32); 

	head();
%><form method="POST" >
	<input type="submit"  value="New" name="Option">
</form>

<style>
tr:nth-child(even){
	background-color: #fafafa;
}
</style>

<table id="tab1" >
	<thead>
		<tr>
			<th>Product Key</th>
			<th>Product ID</th>
			<th>Description</th>
			<th>Manufacturer ID</th>
			<th>Price</th>
			<th>Stock Count</th>
			<th>Stock Date</th>
		</tr>
	</thead>
<%
	// Now reload the list, e.g. Set lower limit with *loval is the first record 
	// then repeat reading until end-of-file or counter exhausted
	// -------------------------------------------------------------------------
	i = 0;                                                                   
	urlManuId = qryStr ('MANUID');
	setll *loval listRec;
	read listRec;  
	dow (not %eof(listFile) and i < 2000) ; 
		i += 1;
		if manuid = urlManuId or  urlManuId <= '';		
			// Put the table row
			// -----------------
			%><tr onclick="location.href='?rrn=<% = %char(rrn)%>'">
				<td align="right"><% = %char(PRODKEY) %></td>
				<td><% = PRODID %></td>
				<td><% = DESC %></td>
				<td><% = MANUID %></td>
				<td align="right"><% = %char(PRICE) %></td>
				<td align="right"><% = %char(STOCKCNT) %></td>
				<td align="right"><% = %char(STOCKDATE) %></td>
			</tr><%
		endif;
		// ready for the next row
		// ----------------------
		read listrec;  
	EndDo;                                                                          

	%></table>
	<script>
	var r = document.getElementById('tab1');
	var l = r.rows[1].cells.length;
	for (var i = 0; i<l; i++) {
		var v1 = r.rows[0].cells[i].clientWidth;
		var v2 = r.rows[1].cells[i].clientWidth;
		var  v = v1 > v2 ? v1 : v2;
		r.rows[0].cells[i].style.width = v;
		r.rows[1].cells[i].style.width = v;
	}
	</script> 

	<%
	tail();
end-proc;

// ------------------------------------------------------------------ *
// Input Form for product   
// ------------------------------------------------------------------ *
dcl-proc inputForm;
	head();
%>
<style>
	label { 
		width: 180px; 
	}
</style>
<form method="POST">
	<input type="hidden" name="sys.rrn" value="<% =  %char(rrn) %>"/>
	<label>Product Key</label>
	<input type="text" name="PRODKEY" value ="<% = %char(PRODKEY) %>"/>
	<br/>
	<label>Product ID</label>
	<input type="text" name="PRODID" size="<%= %char(%size(PRODID))%>" maxlength="<%= %char(%size(PRODID))%>" value ="<% = PRODID %>"><br/>
	<label>Description</label>
	<textarea name="DESC"  rows="4" cols="64" maxlength="<%= %char(%size(DESC))%>"><% = DESC %></textarea><br/>
	<label>Manufacturer ID</label>
	<input type="text" name="MANUID" size="<%= %char(%size(MANUID))%>" maxlength="<%= %char(%size(MANUID))%>" value ="<% = MANUID %>"><br/>
	<label>Price</label>
	<input type="text" name="PRICE" value ="<% = %char(PRICE) %>"><br/>
	<label>Stock Count</label>
	<input type="text" name="STOCKCNT" value ="<% = %char(STOCKCNT) %>"><br/>
	<label>Stock Date</label>
	<input type="text" name="STOCKDATE" size="<%= %char(%size(STOCKDATE))%>" maxlength="<%= %char(%size(STOCKDATE))%>" value ="<% = %char(STOCKDATE) %>"><br/>
	<br/><br/>
	<input type="submit"  value="Update" name="Option">
	<input type="submit"  value="Delete" name="Option">
	<input type="submit"  value="Return" name="Option">
</form>
<%
	tail();
end-Proc;

<%@ language="RPGLE" free="true" %>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) main(sayHello); 

/* -----------------------------------------------------------------------------

	CRTICEPGM STMF('/www/IceBreak-Samples/hello2.rpgle') SVRID(samples)

   	Send greetings as a JSON object

	Showcase: 
		Block comment
		String templates

 
	http://sandbox.icebreak.org:60060/hello2.rpgle?message=My%20name%20is%20John
	http://my_ibm_i:60060/hello2.rpgle?message=My%20name%20is%20John

\* -------------------------------------------------------------------- */
dcl-proc sayHello;

	
	dcl-s  message      varchar(256);
	dcl-s  res          varchar(4096);
	  
	// Get the data from the URL
	message = reqStr('message');

	// Send the response back to client in JSON format
	setContentType('application/json;charset=utf-8');
	res = strFormat (`
		{
			"text" : "Hello world. ${ message }, time is ${ %char(%timestamp()) }" 
		}
	`); 
	
	responseWrite(res);

end-proc;

<%@ language="RPGLE"%>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) main(sayHello); 

/* -----------------------------------------------------------------------------

	CRTICEPGM STMF('/www/IceBreak-Samples/hello.rpgle') SVRID(samples)

   	Send greetings as a JSON object

	Showcase: 
		- Block comment   : https://ibm-power-systems-cc.ideas.ibm.com/ideas/IBMI-I-1577
		- Render engine

	http://sandbox.icebreak.org:60060/hello1.rpgle?message=My%20name%20is%20John
	http://my_ibm_i:60060/hello1.rpgle?message=My%20name%20is%20John

\* -------------------------------------------------------------------- */
dcl-proc sayHello;

	
	dcl-s  message      varchar(256);
	dcl-s I	int(5);
	  
	// Get the data from the URL
	message = qryStr('message');

	// Send the response back to client in JSON format
	// Here we use the render engine directly. 
	// Usefull - but not recomended. Rather use noxDb JSON feature ( it is build in)    
	setContentType('application/json;charset=utf-8');
	%>{
		"text" : "Hello world. <%= message %>, time is <%= %char(%timestamp())%>" 
	}<%

end-proc;

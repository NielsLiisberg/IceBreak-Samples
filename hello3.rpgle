<%@ language="RPGLE" free="true" %>
<%
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.) main(sayHello); 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

	CRTICEPGM STMF('/www/IceBreak-Samples/hello3.rpgle') SVRID(samples)

   	Send greetings as a JSON object

	Showcase: 
		Block comment   : https://ibm-power-systems-cc.ideas.ibm.com/ideas/IBMI-I-1577
		String templates: https://ibm-power-systems-cc.ideas.ibm.com/ideas/IBMI-I-1525
		noxDb

 
	http://sandbox.icebreak.org:60060/hello3.rpgle?message=My%20name%20is%20John
	http://my_ibm_i:60060/hello3.rpgle?message=My%20name%20is%20John

\* -------------------------------------------------------------------- */
/include noxDB
  
dcl-proc sayHello;

	
	dcl-s  message      varchar(256);
	dcl-s  res          pointer;
	  
	// Get the data from the URL
	message = reqStr('message');

	// Send the response back to client in JSON format
	// Here we use the template engine - note the back qote ` and the ${ ..rpg.. }
	// Also we use the noxDb JSON feature ( it is build in):
	//   https://sitemule.github.io/noxdb/about
	//   http://my_ibm_i:7000    
	setContentType('application/json;charset=utf-8');

	res = json_newObject(); 
	json_setStr ( res : 'text' : `Hello world. ${ message }, time is ${ %char(%timestamp()) }` ); 
	responseWriteJson(res);
	json_delete(res);

end-proc;

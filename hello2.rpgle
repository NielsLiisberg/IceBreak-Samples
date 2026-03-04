**free
//<%@ language="RPGLE"%>
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) main(sayHello); 

/* -----------------------------------------------------------------------------

	CRTICEPGM STMF('/www/IceBreak-Samples/hello2.rpgle') SVRID(samples)

   	Send greetings as a JSON object

	Showcase: 
		Block comment   : https://ibm-power-systems-cc.ideas.ibm.com/ideas/IBMI-I-1577
		String templates: https://ibm-power-systems-cc.ideas.ibm.com/ideas/IBMI-I-1525


	http://sandbox.icebreak.org:60060/hello2.rpgle?message=My%20name%20is%20John
	http://my_ibm_i:60060/hello2.rpgle?message=My%20name%20is%20John

\* -------------------------------------------------------------------- */
dcl-proc sayHello;

	
	dcl-s  message      varchar(256);
	dcl-s  res          varchar(4096);
	  
	// Get the data from the URL
	message = reqStr('message');

	// Send the response back to client in JSON format
	// Here we use the template engine - note back qote ` and the ${ ..rpg.. }
	// Usefull - but not recomended. Rather use noxDb JSON feature ( it is build in)    
	setContentType('application/json;charset=utf-8');
	res = strFormat (`
		{
			"text" : "Hello world. ${ message }, time is ${ %char(%timestamp()) }" 
		}
	`); 

	responseWrite(res);

end-proc;

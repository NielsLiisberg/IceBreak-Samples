**free
//<%@ language="RPGLE"%>
ctl-opt copyright('System & Method (C), 2019-2026');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('ICEBREAK':'ICEUTILITY');
// -----------------------------------------------------------------------------
//
//	CRTICEPGM STMF('/www/IceBreak-Samples/hello1.rpgle') SVRID(samples)
//
//   	Send greetings as a JSON object
//
//	Showcase: 
//
//	http://sandbox.icebreak.org:60060/hello0.rpgle?message=My%20name%20is%20John
//	http://my_ibm_i:60060/hello0.rpgle?message=My%20name%20is%20John
//
// -----------------------------------------------------------------------------
/include qrpgleref,icebreak
/include qrpgleref,iceutility

dcl-proc main;
	
	dcl-s  message      varchar(256);
	dcl-s I	int(5);
	  
	// Get the data from the URL
	message = qryStr('message');

	// Send the response back to client in JSON format
	// Here we use the render directly by string concatenation. 
	// Usefull - but not recomended. Rather use noxDb JSON feature ( it is build in)    
	setContentType('application/json;charset=utf-8');
	responseWrite ('{ "text" : "Hello, ' + message + ', time is : ' + %char(%timestamp()) +'"}');

end-proc;

<%@ language="RPGLE"%>
<%
ctl-opt copyright('System & Method (C), 2016');
ctl-opt decEdit('0,') datEdit(*YMD.) main(sayHello); 

/* -----------------------------------------------------------------------------

    CRTICEPGM STMF('/www/IceBreak-Samples/hello.aspx') SVRID(samples)

   	Send greetings as a JSON object
 
	dksrv206:60060/hello.aspx?message=My name is John

\* -------------------------------------------------------------------- */
dcl-proc sayHello;

	
	dcl-s  message      varchar(256);
      
    // Get the data from the URL
    message = qryStr('message');

    // Send the reeating back
    setContentType('application/json;charset=utf-8');
    %>{
        "text" : "Hello world. <%= message %>, time is <%= %char(%timestamp())%>" 
    }<%

end-proc;

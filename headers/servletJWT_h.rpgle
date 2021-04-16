**FREE
// Until these are put in "threadsafe"

Dcl-PR base64DecodeStr   VarChar(32767)  extproc(*CWIDEN:'Base64DecodeStr');                            
   srcString             VarChar(32767) const options(*varsize);                               
   srcCCSID                  Uns(5:0) value options(*nopass);        // Optional: the source   
   dstCCSID                  Uns(5:0) value options(*nopass);        // Optional: the EBCDIC   
End-PR;                                                                                        
                                                                                               
Dcl-PR base64EncodeStr   VarChar(32767)  extproc(*CWIDEN:'Base64EncodeStr');                            
   srcString             VarChar(32767) const options(*varsize);                               
   srcCCSID                  Uns(5:0) value options(*nopass);        // Optional: the ASCII    
   dstCCSID                  Uns(5:0) value options(*nopass);        // Optional: the output   
End-PR;                                                                                        


dcl-pr sys_getUtcOffset extproc('CEEUTCO');
	offsetHours int(10);
	offsetMinutes int(10);
	offsetSeconds float(8);
	feedback char(12) options(*omit);
end-pr;

dcl-c UNIX_EPOCH_START z'1970-01-01-00.00.00.000000';
dcl-s UTF8_PERIOD char(1) inz('.') CCSID(*UTF8);

dcl-s signKey like(jwt_signKey_t) static(*allthread) ccsid(*utf8);

dcl-pr jobLog int(10) extproc('Qp0zLprintf');
    fmtstr pointer value options(*string); // logMsg
    p01    pointer value options(*string:*nopass); 
    p02    pointer value options(*string:*nopass); 
    p03    pointer value options(*string:*nopass); 
end-pr;

**FREE
/* ------------------------------------------------------------------------------
   Example of upload file with multipart mine 
   ------------------------------------------------------------------------------ */
ctl-opt copyright('Sitemule.com (C), 2023');
ctl-opt decEdit('0,') datEdit(*YMD.) ;
ctl-opt debug(*yes) bndDir('NOXDB');
ctl-opt main(main);

/include qrpgleref,noxdb
/include qrpgleref,ifs

/* ------------------------------------------------------------------------------
   Program Entry Point
   ------------------------------------------------------------------------------ */
dcl-proc main;

    if getServerVar('REQUEST_METHOD') = 'POST';
        upload();
    elseif reqStr('retrieveFile') > '';
        retrieveFile();
    else;
        showUploadForm();
    endif;

end-proc;

 /* ------------------------------------------------------------------------------
    if we have a GET ?retrieveFile=TheFileToRetrive the we returns that
    ------------------------------------------------------------------------------ */
dcl-proc retrieveFile;

    dcl-s includeFile  varchar(256);
    dcl-s mimeType     varchar(256);
    dcl-s errorMessage varchar(256);
    dcl-s pResponse     pointer; 

    // Anywhere protected on the IFS 
    includeFile = '/uploads/' + reqStr('retrieveFile');
    mimeType = getMimeType(includeFile);

    setContentType(mimeType);
    setCacheTimeOut(60); // This file will be available for one minute ( never set it to zero)

    // Load the stream file into the response object and chunk it out the the client
    // If an error occurs, you can return a JSON object or set the response status
    errorMessage  = include(includeFile); 
    if errorMessage > '';
        setCacheTimeOut(0); // Never cacnhe real application data 
        setContentType('application/json');
        pResponse  = json_newObject();
        json_setBool (pResponse : 'success' : *OFF);
        json_setStr  (pResponse : 'message' : errorMessage);
        setStatus ('401 '+ errorMessage);
        responseWriteJson( pResponse);

    endif;
    return;

on-exit;    
    json_delete(pResponse);
end-proc;
 /* ------------------------------------------------------------------------------
    Do the upload from multipart mime to the secure IFS location
    ------------------------------------------------------------------------------ */
dcl-proc upload;

    dcl-s remotename    varchar(256);
    dcl-s localname     varchar(256);
    dcl-s uploadname    varchar(256);
    dcl-s finalname     varchar(256);

    dcl-s i             int(5);
    dcl-s pResponse     pointer; 
    dcl-s pFile         pointer; 
    dcl-s filesOnForm   int(5); 
 
    setContentType('application/json');

    pResponse = json_newArray (); 
    filesOnForm = formNum('file.count');
    for i = 1 to filesOnForm;
        remotename = form(`file.${%char(i)}.remotename`);
        localname  = form(`file.${%char(i)}.localname`);
        uploadname = form(`file.${%char(i)}.uploadname`);
        
        if remotename > '';
            mkdir ('/uploads');            
            pFile  = json_newObject();
            finalname = `/uploads/${remotename}`;
            json_setStr (pFile : 'remotename' : remotename);
            json_setStr (pFile : 'localname'  : localname);
            json_setStr (pFile : 'uploadname' : uploadname);
            json_setStr (pFile : 'finalname'  : finalname);
 
            if rename( localname :finalname) = 0;
                json_setBool (pFile : 'success' : *ON );
                // A link to open the file - just for the test: 
                json_setStr (pFile : 'link'  : getHeader('Referer') + '?retrieveFile=' + remotename);
            else; 
                json_setBool (pFile : 'success' : *OFF);
                json_setStr  (pFile : 'message' : getLastError('*MSGTXT'));
            endif;
            json_arrayPush ( pResponse : pFile );
        endIf;

    endfor;

    responseWriteJson( pResponse);
    return;

on-exit;    
    json_delete(pResponse);

end-proc;

/* ------------------------------------------------------------------------------
   Simple inline html form
   ------------------------------------------------------------------------------ */
dcl-proc showUploadForm;
%>
<html>
    <head>
        <link rel="stylesheet" type="text/css" href="/System/Styles/IceBreak.css"/>
    </head>
    <body>
    <form method="post" enctype="multipart/form-data" action="Uploadx1" accept-charset="utf-8">
        <br/>File to upload :<input name="anyname" type="file" size=40>
        <br/><input type="submit" value="Upload">
    </form>
</html>
<%
end-proc;

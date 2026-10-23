**free
//   --------------------------------------------------------------------------------------------------------------
//   Copyright [2019] [System & Method A/S]
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//   --------------------------------------------------------------------------------------------------------------
//
//   Project . . . : IceBreak
//   Design  . . . : Niels Liisberg
//   Function  . . : Sample service program to show prerequest servlet in action
//
//     First you need to setup the <plugin> tag in the webconfig to point to this
//     service program and procedure :
//
//      <!-- to handle the session by API, please look at the SVCSESMAN examples -->
//      <plugin>
//         <map function="preRequest"  pgm="svcSesMan" lib="*LIBL" proc="preRequest"/>
//      </plugin>
//
//     So you have to implement the "preRequest" procedure like in this example.
//
//     Also note: Your procedures need to be written re-entrant. It need to be thread safe
//     that is:
//
//         DONT USE:
//           ANY GLOBAL VARIABLES
//           ANY GLOBAL FILES
//           CALL TO CL PROGRAMS
//         .. unless You know what you are doing (I.e. using mutexes or semaphors)
//
//     Read more here:
//
//     http://publib.boulder.ibm.com/infocenter/iadthelp/v6r0/index.jsp?topic=/com.ibm.etools.iseries.pgmgd.doc/c09
//
//   Compile:  CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/svcSesMan.rpgle') SVRID(samples)
//
//   By       Date       Task    Description
//   -------- ---------- ------- ----------------------------------------------------------------------------------
//   NLI      14.06.2019 0000000 New program
//   --------------------------------------------------------------------------------------------------------------
ctl-opt nomain;
ctl-opt copyright('System & Method A/S (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt bndDir('ICEBREAK');
ctl-opt debug(*yes);
ctl-opt thread(*CONCURRENT);

// Note!! You need to use the servlet headers - NO IceBreak call back are allowed here
/Include qrpgleref,servlet

// --------------------------------------------------------------------------------------------------------------
// Note: This is the name defined in "webconfig.xml"
// Note: servlets have always the same signatur (request : response) and returns *ON if no further action
//
// You have 100% access to both the request and  response and you can diable
// everyhring in the normal IceBreak flow:
//
// Here we just call a very simple session manager that
// overrides the native IceBreak session manager
//
// --------------------------------------------------------------------------------------------------------------
dcl-proc preRequest export;

  dcl-pi *n ind;
    req  pointer value;
    res  pointer value;
  end-pi;

  mySessionManager ( req : res);

  // *OFF: Continue the normal server flow
  // *ON : Dont continue,  break the flow - we have served what is need
  return *off;

end-proc;
// --------------------------------------------------------------------------------------------------------------
// A simple session manager implementation
// --------------------------------------------------------------------------------------------------------------
dcl-proc mySessionManager export;

  dcl-pi *n;
    req  pointer value;
    res  pointer value;
  end-pi;

  dcl-s cookie varchar(4096);
  dcl-s temp   varchar(256);
  dcl-s sesid  timestamp;
  dcl-s p      int(5);

  sesid  = %timestamp(); // default if none found
  cookie =   req_header ( req  : 'Cookie');
  if cookie > '';
    p = %scan ('mysession=' : cookie);
    if p > 0;
        temp =  %subst( cookie : p + 10 : 26);
        sesid = %timestamp(temp);
    endif;
  endif;

  // By setting the session id we disables the buildin session manager
  // Note: it has to be a valid time stamp since that is the primary key in icebreak
  // for session variables. How it is stored in the browser is however 100% up to you
  // and it dont have to be a timestamp - as long you can map you session
  // to a icebreak session timestamp
  req_setSessionId(req : sesid );

  // Elsewhere ( not nesseary in this code but i.e. in a pre-response plugin)
  // you can use getSessionId to retrive the value you set in setSessionId
  // It can be used as a key for what ever
  // sesid = req_getSessionId(req);
  res_setHeader (res: 'Set-Cookie':  'mysession=' + %char(sesid) + '; Version=1; Path=/ ; Discard');

end-proc;

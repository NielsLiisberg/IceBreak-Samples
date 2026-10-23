**FREE
//   --------------------------------------------------------------------------------------------------------------
//   Copyright [2023] [System & Method A/S]
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
//      <!-- to handle the session by API, please look at the WHITELIST example  -->
//      <plugin>
//         <map function="preRequest"  pgm="whitelist" lib="*LIBL" proc="whitelist"/>
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
//         .. unless You know what you are doing (I.e. using mutexes or semaphore)
//
//
//   Compile:  CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/whitelist.rpgle') SVRID(samples)
//
//   By       Date       Task    Description
//   -------- ---------- ------- ----------------------------------------------------------------------------------
//   NLI      17.07.2023 0000000 New program
//   --------------------------------------------------------------------------------------------------------------
ctl-opt nomain;
ctl-opt copyright('System & Method A/S (C), 2023');
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
// You have 100% access to both the request and  response and you can disable
// everything in the normal IceBreak flow:
//
// Here we just call a very simple test on remote IP address
//
// --------------------------------------------------------------------------------------------------------------
dcl-proc whitelist  export;

  dcl-pi *n ind;
    req  pointer value;
    res  pointer value;
  end-pi;

  dcl-s ip varchar(16);

  ip = req_header ( req : 'x-forwarded-for');

  if ip = '' ;
    ip = req_serverVar ( req : 'REMOTE_ADDR');
  endif;

  // Only this client may come in - put your own address (192.0.2.10 is a documentation address)
  if ip <> '192.0.2.10' ;
      res_setStatus ( res : '403 Forbidden');
      return  *ON ; // Don't continue,  break the flow - we have served what is need
  endif;


  // *OFF: Continue the normal server flow
  return *off;

end-proc;

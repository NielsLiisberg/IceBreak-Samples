**free
// ------------------------------------------------------------------------
// Copyright [2019] [System & Method A/S]

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ------------------------------------------------------------------------

// Project . . . : IceBreak
// Design  . . . : Niels Liisberg
// Function  . . : Web socket: an echo server
//
//   Each web socket is a procedure in a service program, routed in webconfig.xml - note
//   the "proc" attribute:
//
//       <routing strict="false">
//           <map pattern="icewebsock/echo" pgm="icewebsock" lib="*LIBL" proc="echo"/>
//       </routing>
//
//   The web socket is loaded when the server instance is started or restarted. Connect to
//   ws://myibmi:60000/icewebsock/echo and everything you send comes back.
//
//   It runs in the HTTP server's threads, so it must be re-entrant and thread safe:
//   no global variables, no global files, no calls to CL programs - unless you know what
//   you are doing (mutexes or semaphores). The normal IceBreak API (iceutility) is not
//   available here: use the servlet / websockets headers instead.
//
//   Compile:  CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/iceWebSock.rpgle') SVRID(samples)
//
// By       Date       Task    Description
// -------- ---------- ------- --------------------------------------------
// NLI      14.06.2012 0000000 New program
// ------------------------------------------------------------------------
Ctl-Opt debug(*yes);
Ctl-Opt thread(*SERIALIZE);
Ctl-Opt DECEDIT('0,') DATEDIT(*YMD.)  COPYRIGHT('System & Method (C), 2019');
Ctl-Opt bnddir('ICEBREAK');
Ctl-Opt NoMain;
/include qrpgleref,websockets

// ------------------------------------------------------------------------
// Plugin to handle the websocket
// this can be invoked from the url:
// http://myibmi:60000/icewebsock/echo
// ------------------------------------------------------------------------
Dcl-Proc echo export;

  Dcl-PI *N;
    socketHandle   Pointer    VALUE;
  End-PI;

  Dcl-S data         Varchar(32760);

  // socket_connected() returns *ON as long the websocket is alive
  // note: has data will also return true for timeouts, but then the
  //       the data lenght will be zero, so this sample will send zero packetets
  //       for each time out
  dow socket_connected(socketHandle);
      socket_read ( socketHandle : data : %len(data:*MAX) : 10);
      socket_write( socketHandle : data);
  enddo;


End-Proc;

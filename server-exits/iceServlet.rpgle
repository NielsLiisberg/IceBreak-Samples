**free
// ------------------------------------------------------------------------
// Copyright [2012] [System & Method A/S]

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
// Function  . . : RPG servlet: answer a request in the HTTP server itself
//
//   A servlet is a procedure in a service program that the HTTP server calls directly,
//   without the application server job. Route a URL to it in webconfig.xml:
//
//       <routing strict="false">
//           <map pattern="^\/servlet\/hello" pgm="iceservlet" lib="*LIBL" proc="sayHello"/>
//       </routing>
//
//   and try  http://myibmi:60000/servlet/hello?name=John&age=42
//
//   A servlet returns *ON when it has served the request, *OFF to let IceBreak continue.
//
//   It runs in the HTTP server's threads, so it must be re-entrant and thread safe:
//   no global variables, no global files, no calls to CL programs - unless you know what
//   you are doing (mutexes or semaphores). The normal IceBreak API (iceutility) is not
//   available here: use the servlet / websockets headers instead.
//
//   Compile:  CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/iceServlet.rpgle') SVRID(samples)
//
// By       Date       Task    Description
// -------- ---------- ------- --------------------------------------------
// NLI      14.06.2012 0000000 New program
// ------------------------------------------------------------------------
Ctl-Opt debug(*yes);
ctl-opt thread(*CONCURRENT);
Ctl-Opt decedit('0,') DATEDIT(*YMD.);
Ctl-Opt copyright('System & Method (C), 2012');
Ctl-Opt bnddir('ICEBREAK');
Ctl-Opt NoMain;
/include qrpgleref,servlet


// ------------------------------------------------------------------------
// Plugin to change the incoming URL
// - You can use parameters to the URL or change it completly
// ------------------------------------------------------------------------
Dcl-Proc sayHello export;

  Dcl-PI *N Ind;
    req            Pointer    value;
    res            Pointer    value;
  End-PI;

  Dcl-S name         Varchar(256);
  Dcl-S age          Int(5);

  name = req_str (req:'name');
  age  = req_num (req:'age');
  res_write(res : 'Hello ' + name + '. Are you ' +
      %char(age) + ' years old?'
  );

  // Data is served, we are done
  return *ON;

End-Proc;

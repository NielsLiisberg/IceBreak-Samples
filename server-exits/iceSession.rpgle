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
// Function  . . : Session exit program: handle session events
//
//   IceBreak calls this program when a session event occurs - set it in the server's
//   webconfig.xml (in the server root folder):
//
//       <session exitPgm="MYLIB/ICESESSION" />
//
//   An event may come more than once, and not always in the same job. The event types are
//   defined in qrpgleref/iceutility (subject to change):
//
//       0-9   N/A         reserved
//       10    IJ_TIMEOUT  session job timeout
//       20    IJ_SESSEND  the session ended
//
//   Compile:  CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/iceSession.rpgle') SVRID(samples)
//
// By       Date       Task    Description
// -------- ---------- ------- --------------------------------------------
// NLI      26.10.2012 0000000 New program
// ------------------------------------------------------------------------
Ctl-Opt decEdit('0,') datEdit(*YMD.)  copyright('System & Method (C), 2012');
Ctl-Opt debug(*yes);
Ctl-Opt bnddir('ICEUTILITY');
Ctl-Opt dftactgrp(*NO);
Ctl-Opt actgrp('QILE');


/include qrpgleref,iceutility


  dcl-pi *N;
    pmSession       timestamp ;
    pmEvent         Int(10)   ;
  end-pi;

  select;
    when pmEvent = IJ_TIMEOUT;
      sndDiag ('My session: ' + %char(pmSession) + ' timed out');
    when pmEvent = IJ_SESSEND;
      sndDiag ('My session: ' + %char(pmSession) + ' ended ');
    other;
      sndDiag ('Unknown event ' + %Char(pmevent) );
  endsl;

  return;

# Server exits and plugins

Programs the IceBreak server calls itself - for a session event, a request nothing else
handles, a request before it is served - plus servlets and web sockets that run inside the
HTTP server. Each one is wired up in the server's `webConfig.xml`.

| Sample | What | Wired up in `webConfig.xml` |
|--------|------|-----------------------------|
| [svcDefault.rpgle](svcDefault.rpgle) | **SVCDEFAULT**: the default response - 404s, errors, a default document of `*NONE`, other HTTP methods (WEB-DAV). IceBreak's own fallback `SVCDEFAUL2` is this code | put a program named `SVCDEFAULT` in the application library, or `<session defaultPgm="MYLIB/MYDEFAULT"/>` |
| [iceSession.rpgle](iceSession.rpgle) | **Session exit**: called on session timeout and session end | `<session exitPgm="MYLIB/ICESESSION"/>` |
| [svcSesMan.rpgle](svcSesMan.rpgle) | **Pre-request plugin**: your own session manager (a cookie instead of IceBreak's) | `<plugin><map function="preRequest" pgm="svcSesMan" lib="*LIBL" proc="preRequest"/></plugin>` |
| [whitelist.rpgle](whitelist.rpgle) | **Pre-request plugin**: let only one client IP address in, 403 for the rest | `<plugin><map function="preRequest" pgm="whitelist" lib="*LIBL" proc="whitelist"/></plugin>` |
| [iceServlet.rpgle](iceServlet.rpgle) | **Servlet**: answer a request in the HTTP server itself, without the application server job | `<routing><map pattern="^\/servlet\/hello" pgm="iceservlet" lib="*LIBL" proc="sayHello"/></routing>` |
| [iceWebSock.rpgle](iceWebSock.rpgle) | **Web socket**: an echo server | `<routing><map pattern="icewebsock/echo" pgm="icewebsock" lib="*LIBL" proc="echo"/></routing>` |
| [iceDtaq.clle](iceDtaq.clle) | **Data queue**: put a message on a keyed data queue that a browser picks up with `/system/rcvdtaq` (non-blocking) | - |

Servlets, web sockets and pre-request plugins run in the HTTP server's threads: write them
re-entrant (no global variables or files, no CL calls) and use the `servlet` / `websockets`
headers, not the normal IceBreak API.

## Compile

With IceBreak on the library list, as the other samples (see the [main README](../README.md)):

```
CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/svcDefault.rpgle') SVRID(samples)
CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/iceSession.rpgle') SVRID(samples)
...
CRTBNDCL PGM(MYLIB/ICEDTAQ) SRCSTMF('/www/IceBreak-Samples/server-exits/iceDtaq.clle')
```

Restart the server after changing `webConfig.xml` - plugins, servlets and web sockets are
loaded when it starts.

These samples were IceBreak's classic `QSAMPLE` source file.

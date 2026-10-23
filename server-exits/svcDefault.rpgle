**FREE
ctl-opt bnddir('ICEUTILITY');
/include qasphdr,iceutility
/* 	-----------------------------------------------------------------------------
 * 	Default response (SVCDEFAULT)
 *  IceBreak calls SVCDEFAULT for everything no other program handles: 404s, errors, a
 *  default document of *NONE, and HTTP methods other than GET and POST (e.g. WEB-DAV).
 *  Put your own SVCDEFAULT in the application library - this is a template to start
 *  from. Without one, IceBreak uses its built-in fallback SVCDEFAUL2 (this same code).
 *  Or name another program in webconfig.xml:  <session defaultPgm="MYLIB/MYDEFAULT" />
 *
 *  Compile:
 *
 *     CRTICEPGM STMF('/www/IceBreak-Samples/server-exits/svcDefault.rpgle') SVRID(samples)
 *
 *  by         date       fix
 *  ---------- ---------- -------------------------------------------------------
 *  NLI        22-12-2022 Chunked need to set headers before including response data
 * 	----------------------------------------------------------------------------- */

dcl-s method   varchar(16);
dcl-s host     varchar(128);
dcl-s resource varchar(256);
dcl-s href     varchar(256);
dcl-s url      varchar(256);
dcl-s err      varchar(256);
dcl-s i        int(10);
dcl-s msgid    char(7);

/* 	-----------------------------------------------------------------------------
	Main
	----------------------------------------------------------------------------- */
	*INRT = *ON;

	SetContentType('text/plain; charset=UTF-8');

	monitor;
		method = UpperCase(getServervar('REQUEST_METHOD'));
	on-error;
		setStatus ('405 ' + 'Invalid blank method');
		return;
    endmon;

	select;
		when method = 'OPTIONS';
			exsr options;
		when method = 'GET'
		or   method = 'POST'
		or   method = 'HEAD';
			exsr handleError;
		other;
			setStatus ('405 ' + 'Invalid method: ' + method);
	endsl;
// 	-----------------------------------------------------------------------------
begsr options;

	// Force Microsoft to use DAV
	//setHeader('MS-Author-Via':'DAV');

	setHeader('Allow' :
		'OPTIONS, GET, HEAD, POST');
endsr;

// -------------------------------------------------------------------------------------------------
begsr handleError;

	SetContentType('text/html; charset=UTF-8');

	// peek the resource (rcs) from the current URL
	url  = lowerCase(getServerVar('REQUEST_URL'));
	if %scan ('favicon.ico':url) > 0;
		SetContentType('image/x-icon; charset=UTF-8');
		if ('' = include(
			'favicon.ico' :
			'./system/images:./system/shared/images'
			));
			return; // Return if no error
		endif;
	endif;

	// Only show joblog in development mode
	if getServerVar('server_job_mode') = '*DEVELOP';
		setMarker('joblog' :
			'<iframe class="logframe" src="/system/dspjoblog.aspx" -
			</iframe>'
		);
	else;
		setMarker('joblog' : '');
	endif;


	msgId = getLastError('*MSGID');

	if wordIx('CPF9802' : msgid : ',') > 0;

		setStatus ('403 Not authorized '
			+ url
			+ ' in server '
			+ getServerVar('SERVER_ID')
		);

		setMarker('msg' :
			'403 ' + getLastError('*MSGTXT')
			+ ' for ' +url
		);

		err = include(
			'403.html' :
			'./Errors:./system/shared/Errors:./system/Errors'
		);

		if err > '';
			exsr dftErrorDoc;
		endif;

	elseif wordIx('CPD0170,CPF9801' : msgid : ',') > 0 or msgid = ' '; // Blank is from Front end server => Not found

		setStatus ('404 Not found '
			+ url
			+ ' in server '
			+ getServerVar('SERVER_ID')
		);

		setMarker('msg' :
			'404 Not found - Error opening file or application '
			+ url
			+ ' No such path or directory.'
		);

		err = include(
			'404.html' :
			'./Errors:./system/shared/Errors:./system/Errors'
		);

		if err > '';
			exsr dftErrorDoc;
		endif;

	else;

		SetContentType('text/html; charset=UTF-8');
		setStatus ('500 Internal error '
			+ url
			+ ' in server '
			+ getServerVar('SERVER_ID')
		);

		setMarker('msg' :
			'500 ' + getLastError('*MSGTXT')
			+ ' for ' +url
		);

		err = include(
			'500.html' :
			'./Errors:./system/shared/Errors:./system/Errors'
		);

		if err > '';
			exsr dftErrorDoc;
		endif;
	endif;
endsr;
// -------------------------------------------------------------------------------------------------
begsr dftErrorDoc;
%><!--#include file="./System/errors/404.html" --><%
endsr;
// -------------------------------------------------------------------------------------------------

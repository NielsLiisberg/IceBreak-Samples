<%@ language="RPGLE" pgmtype="SRVPGM" pgmopt="export(*ALL)" %><%
**FREE
ctl-opt nomain;
ctl-opt copyright('System & Method A/S (C) sitemule, 2021');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt bndDir('ICEBREAK');
ctl-opt debug(*yes);
ctl-opt thread(*CONCURRENT);

//   --------------------------------------------------------------------------------------------------------------
//   Copyright [2021] [System & Method A/S]
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
//
//   Prerequest is a special kind of a servlet - a plugin into the normal IceBreak flow
// 
//   to activate you prerequisite - your own service program -  you have to append these tags into the webconfig.xml :
// 
//
//
//     First you need to setup the <plugin> tag in the webconfig to point to this
//     service program and procedure :
//
//      <!-- to handle the session by API, please look at the SVCSESMAN examples -->
//      <plugin>
//         <map function="preRequest"  pgm="servletJWT" lib="*LIBL" proc="validateJWT"/>
//      </plugin>
//
//     In this case your service program called servletJWT  will be loaded once at startup and for each request 
//     you procedure "preRequest" will be called it will hat will be a service 
//     So you have to implement the "preRequest" procedure like in this example.
//
//     Also note: Your procedures need to be written re-entrant. It need to be thread safe
//     so you need the ctl-opt thread(*CONCURRENT)
// 
//     An please note in threadfae applications: 
//     that is:
//
//         DONT USE:
//           ANY GLOBAL VARIABLES
//           ANY GLOBAL FILES
//           CALL TO CL/RPG/COBOL PROGRAMS
//         .. unless You know what you are doing (I.e. using mutexes or semaphors)
//
//     Read more here:
//
//			 https://www.ibm.com/docs/en/i/7.4?topic=applications-multithreaded-programming-techniques
//
//
//   By       Date       Task    Description
//   -------- ---------- ------- ----------------------------------------------------------------------------------
//   NLI      16.04.2021 0000000 New program
//   --------------------------------------------------------------------------------------------------------------

// Note!! You need to use the servlet headers - NO IceBreak call back are allowed here
// Look in  qAspHdr,servlet fro all API's available
/include qAspHdr,servlet
/include qAspHdr,jsonParser
/include qsysinc/qrpglesrc,qusec
/include 'headers/jwt_h.rpgle'
/include 'headers/servletJWT_h.rpgle'


// --------------------------------------------------------------------------------------------------------------
// Note: This is the name defined in "webconfig.xml"
// Note: servlets have always the same signature (request : response) and returns *ON if no further action
//
// You have 100% access to both the request and  response and you can disable
// everything in the normal IceBreak flow:
//
// Here we validate a JWT token, and only if OK it will continu the call to applicatinserver ( pool) 
//
// --------------------------------------------------------------------------------------------------------------
dcl-proc validateJWT export;

	dcl-pi *n ind;
		req  pointer value;
		res  pointer value;
	end-pi;

	dcl-s  jwt 	varchar(8000);
	dcl-s  p   	int(5);

	jwt = req_header ( req : 'Authorization');
	if jwt = ''; 
		res_setStatus ( res : '401 no jwt token provided');
		return *ON; // break flow
	endif;

	// skip the Bearer
	jwt = %triml(jwt);
	p = %scan ('earer' : %triml(jwt));
	if p <= 0; 
		res_setStatus ( res : '401 no Bearer in jwt token provided');
		return *ON; // break flow
	endif;

	jwt = %triml(%subst (jwt : p +6 ));


	// *OFF: Continue the normal server flow
	// *ON : Dont continue,  break the flow - we have served what is need
	return *OFF;

end-proc;

///
// ILEastic : JWT Service Program
//
// This service program offers procedures for signing and verifying JWT tokens.
//
// @author Mihael Schmidt
// @date 04.05.2019
// @project ILEastic
///

dcl-proc jwt_verify;
	dcl-pi *n ind;
		token like(jwt_token_t) const ccsid(*utf8);
		signKey like(jwt_signKey_t) const ccsid(*utf8);
	end-pi;

	dcl-s valid ind inz(*off);
	dcl-s serverSignedToken like(jwt_token_t) ccsid(*utf8);
	dcl-s header like(jwt_token_t) ccsid(*utf8);
	dcl-s payload like(jwt_token_t);
	dcl-s json pointer;

	header = jwt_decodeHeader(token);
	payload = jwt_decodePayload(token);

	serverSignedToken = jwt_sign(jwt_HS256 : payload : signKey);

	if (token = serverSignedToken);
		json = json_parseString(payload);
		valid = (not isExpired(json)) and isActive(json);
		json_close(json);
	endif;

	return valid;
end-proc;


dcl-proc jwt_decodeHeader ;
	dcl-pi *n like(jwt_token_t) ccsid(*utf8);
		token like(jwt_token_t) const ccsid(*utf8);
	end-pi;

	dcl-s x int(10);
	dcl-s decoded like(jwt_token_t) ccsid(*utf8);
	dcl-s header like(jwt_token_t) ccsid(*utf8);

	// JWT header
	x = %scan(UTF8_PERIOD : token);
	if (x = 0);
		return *blank;
	endif;

	header = %subst(token : 1 : x - 1);
	decoded = decodeBase64Url(header);

	return decoded;
end-proc;


dcl-proc jwt_decodePayload ;
	dcl-pi *n like(jwt_token_t) ccsid(*utf8);
		token like(jwt_token_t) const ccsid(*utf8);
	end-pi;

	dcl-s x int(10);
	dcl-s x2 int(10);
	dcl-s decoded like(jwt_token_t) ccsid(*utf8);
	dcl-s payload like(jwt_token_t) ccsid(*utf8);

	// JWT header
	x = %scan(UTF8_PERIOD : token);
	if (x = 0);
		return *blank;
	endif;

	// JWT payload
	x2 = %scan(UTF8_PERIOD : token : x+1);
	if (x2 = 0);
		return *blank;
	endif;

	payload = %subst(token : x+1 : x2 - x);
	decoded = decodeBase64Url(payload);

	return decoded;
end-proc;


dcl-proc jwt_sign ;
	dcl-pi *n like(jwt_token_t) ccsid(*utf8);
		algorithm char(100) const;
		pPayload like(jwt_token_t) const ccsid(*utf8);
		signKey like(jwt_signKey_t) const ccsid(*utf8);
		claims likeds(jwt_claims_t) const options(*nopass);
	end-pi;

	dcl-pr memcpy pointer extproc('memcpy');
		dest pointer value;
		source pointer value;
		count uns(10) value;
	end-pr;

	dcl-pr sys_calculateHmac extproc('Qc3CalculateHMAC');
		input pointer value;
		inputLength int(10) const;
		inputDataFormat char(8) const;
		algorithm char(65535) const;
		algorithmFormat char(8) const;
		key char(1000) const;
		keyFormat char(8) const;
		cryptoServiceProvier char(1) const;
		cryptoDeviceName char(10) const;
		hash char(32);
		errorCode likeds(QUSEC);
	end-pr;

	dcl-ds algd0500_t qualified template;
		algorithm int(10);
	end-ds;

	dcl-c ALGORITHM_SHA256 3;

	dcl-ds keyd0200_t qualified template;
		type int(10);
		length int(10);
		format char(1);
		reserved char(3);
		key char(100) ccsid(*utf8);
	end-ds;

	dcl-s headerPayload char(65535) ccsid(*utf8);
	dcl-s header like(jwt_token_t) ccsid(*utf8);
	dcl-s encoded like(jwt_token_t) ccsid(*utf8);
	dcl-s hash char(32);
	dcl-s tmpHash char(32) ccsid(*utf8);
	dcl-ds algd0500 likeds(algd0500_t);
	dcl-ds keyparam likeds(keyd0200_t) inz;
	dcl-s base64Encoded like(jwt_token_t) ccsid(*utf8);
	dcl-s paddingChar char(1) inz('=') ccsid(*utf8);
	dcl-s payload like(jwt_token_t) ccsid(*utf8);


	if (algorithm <> jwt_HS256);
		joblog('Unsupported algorithm %s' : algorithm);
		return *blank;
	endif;

	header = '{"alg":"' + jwt_HS256 + '","typ":"JWT"}';

	payload = pPayload;
	if (%parms() >= 4);
		payload = addClaims(payload : claims);
	endif;

	base64Encoded = encodeBase64Url(payload);
	base64Encoded = %trimr(base64Encoded : paddingChar);
	headerPayload = encodeBase64Url(header) + '.' + base64Encoded;

	algd0500.algorithm = ALGORITHM_SHA256;
	keyparam.type = 3;
	keyparam.length = %len(%trimr(signKey));
	keyparam.key = signKey;
	keyparam.format = '0';

	// minimum 32 bytes for SHA-256
	if (keyparam.length < 32);
		keyparam.length = 32;
	endif;

	clear QUSEC;
	sys_calculateHmac(
		%addr(headerPayload) :
		%len(%trimr(headerPayload)) :
		'DATA0100' :
		algd0500 :
		'ALGD0500' :
		keyparam :
		'KEYD0200' :
		'0' : // crypto
		*blank : // crypto dev
		hash :
		QUSEC
	);

	memcpy(%addr(tmpHash) : %addr(hash) : 32);

	encoded = encodeBase64Url(tmpHash);
	encoded = %trimr(encoded : paddingChar);

	return %trimr(headerPayload) + UTF8_PERIOD + encoded;
end-proc;


dcl-proc addClaims;
	dcl-pi *n like(jwt_token_t) ccsid(*utf8);
		pPayload like(jwt_token_t) const ccsid(*utf8);
		claims likeds(jwt_claims_t) const;
	end-pi;

	dcl-s payload like(jwt_token_t) ccsid(*utf8);
	dcl-s json pointer;
	dcl-s value like(jwt_token_t);
	dcl-s uxts int(10);
	dcl-s changed ind inz(*off);

	payload = %trimr(pPayload) + x'00';

	json = json_parseString(%addr(payload : *DATA));

	if (%len(claims.issuer) > 0);
		value = claims.issuer + x'00';
		json_setStr(json : 'iss' : %addr(value : *DATA));
		changed = *on;
	endif;

	if (%len(claims.subject) > 0);
		value = claims.subject + x'00';
		json_setStr(json : 'sub' : %addr(value : *DATA));
		changed = *on;
	endif;

	if (%len(claims.audience) > 0);
		value = claims.audience + x'00';
		json_setStr(json : 'aud' : %addr(value : *DATA));
		changed = *on;
	endif;

	if (%len(claims.jwtId) > 0);
		value = claims.jwtId + x'00';
		json_setStr(json : 'jti' : %addr(value : *DATA));
		changed = *on;
	endif;

	if (claims.expirationTime <> *loval);
		uxts = toUnixTimestamp(claims.expirationTime);
		json_setInt(json : 'exp' : uxts);
		changed = *on;
	endif;

	if (claims.notBefore <> *loval);
		uxts = toUnixTimestamp(claims.notBefore);
		json_setInt(json : 'nbf' : uxts);
		changed = *on;
	endif;

	if (claims.issuedAt <> *loval);
		uxts = toUnixTimestamp(claims.issuedAt);
		json_setInt(json : 'iat' : uxts);
		changed = *on;
	endif;

	if (changed);
		payload = json_asJsonText(json);
		json_close(json);
		return payload;
	else;
		json_close(json);
		return pPayload;
	endif;
end-proc;


dcl-proc jwt_isExpired;
	dcl-pi *n ind;
		pPayload like(jwt_token_t) const ccsid(*utf8);
	end-pi;

	dcl-s payload like(jwt_token_t);
	dcl-s expired ind inz(*off);
	dcl-s json pointer;

	payload = pPayload;

	json = json_parseString(payload);
	expired = isExpired(json);
	json_close(json);

	return expired;
end-proc;


dcl-proc isExpired;
  dcl-pi *n ind;
    json pointer const;
  end-pi;

  dcl-s expired ind inz(*off);
  dcl-s exp int(20);
  dcl-s expTimestamp timestamp;
  dcl-s now timestamp;
  dcl-s offsetHours int(10);
  dcl-s offsetMinutes int(10);
  dcl-s offsetSeconds float(8);

  now = %timestamp();
  sys_getUtcOffset(offsetHours : offsetMinutes : offsetSeconds : *omit);

  exp = json_getInt(json : 'exp' : -1);

  if (exp >= 0);
	expTimestamp = UNIX_EPOCH_START + %seconds(exp + %int(offsetSeconds));
	expired = (now >= expTimestamp);
  endif;

  return expired;
end-proc;


dcl-proc isActive;
  dcl-pi *n ind;
    json pointer const;
  end-pi;

  dcl-s active ind inz(*on);
  dcl-s nbf int(20);
  dcl-s nbfTimestamp timestamp;
  dcl-s now timestamp;
  dcl-s offsetHours int(10);
  dcl-s offsetMinutes int(10);
  dcl-s offsetSeconds float(8);

  now = %timestamp();
  sys_getUtcOffset(offsetHours : offsetMinutes : offsetSeconds : *omit);

  nbf = json_getInt(json : 'nbf' : -1);

  if (nbf >= 0);
    nbfTimestamp = UNIX_EPOCH_START 
		+ %seconds(nbf + %int(offsetSeconds));
    active = (now >= nbfTimestamp);
  endif;

  return active;
end-proc;


dcl-proc encodeBase64Url;
  dcl-pi *n varchar(65530) ccsid(*utf8);
    string varchar(65530) const ccsid(*utf8);
  end-pi;

  dcl-s FROM char(2) inz('+/') ccsid(*utf8);
  dcl-s TO   char(2) inz('-_') ccsid(*utf8);
  dcl-s encoded varchar(65530) ccsid(*utf8);

  encoded = base64EncodeStr(string);
  encoded = %xlate(FROM : TO : encoded);

  return encoded;
end-proc;


dcl-proc decodeBase64Url;
  dcl-pi *n varchar(65530) ccsid(*utf8);
    string varchar(65530) const ccsid(*utf8);
  end-pi;

  dcl-s TO   char(2) inz('+/') ccsid(*utf8);
  dcl-s FROM char(2) inz('-_') ccsid(*utf8);
  dcl-s decoded varchar(65530) ccsid(*utf8);
  dcl-s value varchar(65530) ccsid(*utf8);

  value = %xlate(FROM : TO : string);
  decoded = base64DecodeStr(value);

  return decoded;
end-proc;


dcl-proc toUnixTimestamp;
  dcl-pi *n int(10);
    ts timestamp const;
  end-pi;

  dcl-s offsetHours int(10);
  dcl-s offsetMinutes int(10);
  dcl-s offsetSeconds float(8);
  dcl-s uxts int(10);
  
  sys_getUtcOffset(offsetHours : offsetMinutes : offsetSeconds : *omit);
  
  uxts = %diff(ts : UNIX_EPOCH_START : *SECONDS) - %int(offsetSeconds);
  
  return uxts;
end-proc;

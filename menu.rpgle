<%@ free="*YES" language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
/* ----------------------------------------------------------------------------------------
 * Copyright [2018] [System & Method A/S]                                          
 *                                                                                          
 * Licensed under the Apache License, Version 2.0 (the "License");                          
 * you may not use this file except in compliance with the License.                         
 * You may obtain a copy of the License at                                                  
 *                                                                                          
 *     http://www.apache.org/licenses/LICENSE-2.0                                           
 *                                                                                          
 * Unless required by applicable law or agreed to in writing, software                      
 * distributed under the License is distributed on an "AS IS" BASIS,                        
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                 
 * See the License for the specific language governing permissions and                      
 * limitations under the License.                                                           
 * ---------------------------------------------------------------------------------------- 
 *                                                                                                                                                                                    
 * Project . . . : IceBreak                                                                 
 * Design  . . . : Niels Liisberg, System & Method A/S - Sitemule                                                           
 * Function  . . : simple demo menu driver                                                  
 *                                                                                          
 * This program can be used as a basic template for loading application specific menus      
 *                                                                                          
 * It is a menu driver that integrates menu options to the sitemule 
 * admin ( portfolio) menu.  
 *
 * By       Date       Task    Description                                                  
 * -------- ---------- ------- ------------------------------------------------------------ 
 * NLI      18.08.2019 0000000 New program 
 * 
 * Compile:
 
 	CRTICEPGM STMF('/www/IceBreak-Samples/Menu.rpgle') 
 
 * ---------------------------------------------------------------------------------------- */
ctl-opt nomain; 
ctl-opt copyright('System & Method (C), 2019');
ctl-opt decEdit('0,') datEdit(*YMD.); 
ctl-opt bndDir('ICEBREAK' : 'EXTUTILITY');
ctl-opt debug(*yes);

/Include qAspHdr,IceBreak
/Include qAspHdr,IceUtility
/Include qAspHdr,jsonParser
/Include qAspHdr,ExtUtility

/* 	-------------------------------------------------------------------- 

	This is the top level: The MenuTitles

	http://sandbox.icebreak.org:60060/router/menu/listMenuTitles?payload={}
	http://my_ibm_i:60060/router/menu/listMenuTitles?payload={}

 	-------------------------------------------------------------------- */
dcl-proc listMenuTitles export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-ds list         likeds(json_iterator);  
	dcl-s  sql 			varchar(256);
	dcl-s  node			varchar(256);
	dcl-s  search 		varchar(256);
	dcl-s  pRows		pointer;    
	dcl-s  pItem		pointer;    
	dcl-s  pMenu		pointer;    
	dcl-s  i 			int(10);

	if json_getStr(pInput:'search') > '';
		return searchMenuItems(pInput);
	endif;

	node   = json_getStr(pInput:'node':'root');
	pMenu  = json_newArray();

	// return an simple array with all rows       
	sql   = `
		Select * from microserv.menuName
	 	order by 1
	`;

	pRows = json_sqlResultSet(sql);             

	// Now produce the menu JSON 
	list = json_setIterator(pRows);  
	dow json_ForEach(list);  
		i += 1;
		pItem = json_newObject();
		json_copyValue  (pItem : 'text' : list.this : 'menutext');
		json_setStr(pItem : 'id'   : 
			%char(%timestamp()) + '#'+ json_getStr(list.this : 'menuid') ) ;
		json_setBool (pItem : 'leaf'     : *OFF);
		json_setBool (pItem : 'collapsed': *ON);
		json_setStr  (pItem : 'url': '/router/menu/getItemsForMenu');
		json_setStr  (pItem : 'cls' : 'folder');
		//json_setStr  (pItem : 'icon': '/system/images/extjstree/server.gif');
		json_arrayPush(pMenu : pItem);
	enddo;                           
									 
	json_delete(pRows);

	return pMenu;               

end-proc;
/*	-------------------------------------------------------------------- 
	http://sandbox.icebreak.org:60060/router/menu/getItemsForMenu?payload={
		"node" : "123#IBMI"
	}

 	-------------------------------------------------------------------- */
dcl-proc getItemsForMenu export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;


	dcl-ds list         likeds(json_iterator);  
	dcl-s  sql 			varchar(256);
	dcl-s  node			varchar(256);
	dcl-s  search 		varchar(256);
	dcl-s  pRows		pointer;    
	dcl-s  pItem		pointer;    
	dcl-s  pMenu		pointer;    
	dcl-s  i 			int(10);

	search = uppercase(json_getStr(pInput:'search'));
	node   = json_getStr(pInput:'node':'root');
	node   = word(node : 2 :'#'); // Pull the id out - it has to be unique so it is prefiexd with a timestamp 

	pMenu  = json_newArray();

	// return an simple array with all rows       
	sql   = `
		Select * from microserv.menuItem 
		where menuid = ${ strQuot (node) }
	 	order by 1 
	`;

	pRows = json_sqlResultSet(sql);             

	list = json_setIterator(pRows);  
	dow json_ForEach(list);  
		pItem = json_newObject();
		json_copyValue  (pItem : 'text' : list.this : 'menutext');
		// link or (usr if component
		json_copyValue  (pItem : 'url' : list.this : 'menulink');
		json_setBool 	(pItem : 'leaf' : *ON);
		//json_setStr  (pItem : 'icon': '/system/images/extjstree/server.gif');
		json_arrayPush	(pMenu : pItem);
	enddo;

	// widget "demo"
	if (1=1);
		pItem = json_newObject();
		json_setStr  (pItem : 'text' : 'Widget');
		json_setStr  (pItem : 'widget' : 
			'{ xtype: "panel", html: "<p>Hello</p>"}');
		json_setBool (pItem : 'leaf' : *ON);
		json_arrayPush(pMenu : pItem);
	endif;

	json_delete(pRows);


	return pMenu;               

end-proc;


/* -------------------------------------------------------------------- 
	This it a comination - each titel and its coresponding items are 
	joined together
	
	http://sandbox.icebreak.org:60060/router/menu/searchMenuItems?payload={
		"search" : "you"
	}

 -------------------------------------------------------------------- */
dcl-proc searchMenuItems export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-ds list         likeds(json_iterator);  
	dcl-s  sql 			varchar(4096);
	dcl-s  node			varchar(256);
	dcl-s  search 		varchar(256);
	dcl-s  menuTitle	varchar(256);
	dcl-s  prevMenu		varchar(256);
	dcl-s  pRows		pointer;    
	dcl-s  pItem		pointer;    
	dcl-s  pMenu		pointer;    
	dcl-s  pChildren	pointer;    
	dcl-s  pChild		pointer;    
	dcl-s  i 			int(10);

	search = uppercase(json_getStr(pInput:'search'));

	pMenu  = json_newArray();

	// List all menus (titles) and their items 
	sql  = `
		with list as (
		Select 
			a.menuText as menuTitle,
			b.menuText as menuItem,
			upper(a.menuText concat ' ' concat b.menuText) as menuSearch,
			b.menulink
		from menuName a
		join menuItem b 
		on a.menuId = b.menuid
		)
		Select * from list
		where menuSearch like ${ strQuot ('%' + search +'%') }
	 	order by 1 
	`;

	pRows = json_sqlResultSet(sql);             

	list = json_setIterator(pRows);  
	dow json_ForEach(list); 
		menuTitle = json_getStr(list.this : 'menuTitle');
		// For each break on the Menu title
		if menuTitle <> prevMenu;
			pChildren = json_newArray();
			prevMenu = menuTitle;
			
			pItem  = json_newObject();
			json_setStr(pItem:'text' : json_getStr(list.this : 'menuTitle'));
			json_setBool(pItem:'leaf' : *OFF);
			json_setStr(pItem:'cls' : 'folder');
			json_moveObjectInto( pItem : 'children' : pChildren);
			json_arrayPush (pMenu : pItem);
		endif;

		// .. and then the menu item for the menu title
		pChild  = json_newObject();
		json_copyValue  (pChild: 'text' : list.this : 'menuItem');
		json_setBool    (pChild: 'leaf'     : *on);
		json_copyValue  (pChild: 'link' : list.this :  'menuLink');
		json_arrayPush( pChildren: pChild);
	enddo;                           
									 
	json_delete(pRows);

	return pMenu;               

end-proc;

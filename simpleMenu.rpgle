<%@ language="RPGLE" %>
<%
ctl-opt copyright('System & Method (C), 2017');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 

/*  -----------------------------------------------------------------------------


    Simple REST  - showcase that injection is not possible

    Simple menu using static JSON data
       
    Run from the browser:

	http://192.168.5.206:60060/simpleMenu.rpgle


    By     Date       PTF     Description
    ------ ---------- ------- ---------------------------------------------------
    MOP    04.04.2018         New program
    ----------------------------------------------------------------------------- */

 
    dcl-proc main;

        dcl-s  name       varchar(30);
        

        // We will produce JSON in UTF-8 format
        setContentType('application/json;charset=UTF-8');
        name = 'joblog';
    %>
    [
        {
            "id": "MNU0",
            "text": "Links on the net",
            "leaf": false,
            "cls": "folder",
            "icon": "/icebreak-admin/system/images/extjstree/server_earth.gif",
            "expanded": false,
            "children": [
                {
                    "id": "MNU0.1",
                    "text": "Bing",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/server_earth.gif",
                    "url": "http://www.bing.com"
                }
            ]
        },
        {
            "id": "MNU1",
            "text": "Programmers guide",
            "leaf": false,
            "cls": "folder",
            "icon": "/icebreak-admin/system/images/extjstree/folder_cubes.gif",
            "expanded": false,
            "children": [
                {
                    "id": "MNU1.1",
                    "text": "Work with servers",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/server_earth.gif",
                    "url": "/icebreak-admin/system/wrksvr.aspx"
                },
                {
                    "id": "MNU1.2",
                    "text": "Display current server",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/server_information.gif",
                    "url": "/icebreak-admin/system/dspsvrinf.aspx"
                },
                {
                    "id": "MNU1.3",
                    "text": "Display all servers",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/server_view.gif",
                    "url": "/icebreak-admin/system/dspallsvr.aspx"
                },
                {
                    "id": "MNU1.4",
                    "text": "Display header",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/document_preferences.gif",
                    "url": "/icebreak-admin/system/dsphdrinf.aspx"
                },
                {
                    "id": "MNU1.5",
                    "text": "<%= name %>",
                    "leaf": true,
                    "icon": "/icebreak-admin/system/images/extjstree/document_info.gif",
                    "url": "/icebreak-admin/system/dspjoblog.aspx"
                }
            ]
        }
    ]
    <%
  

end-proc;
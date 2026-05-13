begin 
    declare file_name varchar(256);

    -- Build the QRPGLESRC source file if it does not exists     
    begin
		declare continue handler for sqlexception begin end;
		call qcmdexc ('CRTSRCPF FILE(SAMPLES/QRPGLESRC) RCDLEN(150) TEXT(''iceBreak samples source'')');
	end;

    
    -- Copy all sources members to the QRPGLESRC source file
    for 
        select path_name
            from table(qsys2.ifs_object_statistics( 
                object_type_list => '*STMF', 
                start_path_name => '/www/IceBreak-Samples',
                subtree_directories => 'NO'
            ))
        where path_name like '%.rpgle'
    do 
        set file_name = REGEXP_SUBSTR(path_name, '.*/([^/.]+)\.([^/]+)$', 1, 1, '', 1);     
        call qcmdexc ('CPYFRMSTMF FROMSTMF(''' || path_name || ''') TOMBR(''/QSYS.lib/SAMPLES.lib/QRPGLESRC.file/' || file_name || '.mbr'') MBROPT(*REPLACE)'); 
        call qcmdexc ('CHGPFM FILE(samples/qrpglesrc) MBR(' || file_name || ') SRCTYPE(RPGLE) TEXT(''' || file_name || ''')');   
    end for;
end;

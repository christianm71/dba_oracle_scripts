set pagesize 10000 feedback off linesize 300

col "Tablespace" format a30
col "Total Go"   format 99,999.9
col "Free Go"    format 99,999.9
col "% full"     format   a6
col "Status" format a7
col "Extent management" format a17
col "Segment space management" format a24
col "Allocation type" format a15

select df.tablespace_name                               "Tablespace",
       df.total/1024/1024/1024                          "Total Go",
       decode(ds.free, NULL, 0, ds.free/1024/1024/1024) "Free Go",
       trunc(100*(1-ds.free/df.total), 1)||'%'                    "% full",
       df.cnt "Count",
       t.status "Status",
       t.extent_management "Extent management",
       t.segment_space_management "Segment space management",
       t.allocation_type "Allocation type"
from
  (select tablespace_name, sum(bytes) total, count(*) cnt from dba_data_files group by tablespace_name) df,
  (select tablespace_name, sum(nvl(bytes, 0)) free from dba_free_space group by tablespace_name) ds,
  dba_tablespaces t
where
      t.tablespace_name=df.tablespace_name
  and df.tablespace_name=ds.tablespace_name (+)
--
union all
--
-- Temporary tablespace
-----------------------
select tmp.tablespace_name||' (T)' "Tablespace",
       tmp.tablespace_size/1024/1024/1024    "Total Go",
       tmp.free_space/1024/1024/1024     "Free Go",
       trunc(100*(1-free_space/tablespace_size), 1)||'%'          "% full",
       tfiles.cnt "Count",
       t.status "Status",
       t.extent_management "Extent management",
       t.segment_space_management "Segment space management",
       t.allocation_type "Allocation type"
from
  dba_temp_free_space tmp,
  dba_tablespaces t,
  ( select tablespace_name, count(*) cnt from dba_temp_files group by tablespace_name ) tfiles
where
      t.tablespace_name=tmp.tablespace_name
  and t.tablespace_name=tfiles.tablespace_name
order by 1;

col tablespace_name format a30
col file_name       format a70
col "Size Go"       format 999,999.9
col "Max size Go"   format 999,999.9
col "Remains Go"    format 999,999.9

break on tablespace_name skip 1 duplicates

select tablespace_name,
       file_name,
       go "Size Go",
       autoextensible,
       decode(autoextensible, 'YES', max_go, null)    "Max size Go",
       decode(autoextensible, 'YES', max_go-go, null) "Remains Go"
from
  ( select tablespace_name,
           file_name,
           autoextensible,
           bytes/1024/1024/1024 go,
           decode(autoextensible, 'YES', case when maxbytes > bytes then maxbytes else bytes end, bytes)/1024/1024/1024 max_go
    from
      dba_data_files
    union all
    select tablespace_name||' (T)',
           file_name,
           autoextensible,
           bytes/1024/1024/1024 go,
           decode(autoextensible, 'YES', case when maxbytes > bytes then maxbytes else bytes end, bytes)/1024/1024/1024 max_go
    from
      dba_temp_files
  )
order by 1, 2;
exit;

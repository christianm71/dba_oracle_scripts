#!/usr/bin/perl -w

$script=$0;
$script=~s/.*\///;

# ==========================================================================================================================
sub help {
  print "
$script <motif>

        [ -h -help ] : print this help

example : ./$script sqlarea\n\n";
  exit(1);
}

# ==========================================================================================================================
if (scalar(@ARGV) == 0) { help(); }

$motif=lc($ARGV[0]);
$motif=~s/%{2,}/%/g;

# ==========================================================================================================================
$sql="
set linesize 300 pagesize 1000 feedback off

col object_name format a50
col object_type format a70
col created format a20
col last_ddl_time format a20

select O.owner||'.'||O.object_name object_name,
       case
         when O.object_type='SYNONYM' then
           O.object_type||' -> '||( select S.table_owner||'.'||S.table_name||decode(S.db_link, null, '', '\@'||S.db_link) from dba_synonyms S where S.owner=O.owner and S.synonym_name=O.object_name )
         else O.object_type
       end object_type,
       O.status,
       to_char(O.created, 'dd/mm/yyyy hh24:mi:ss') created,
       to_char(O.last_ddl_time, 'dd/mm/yyyy hh24:mi:ss') last_ddl_time
from
  dba_objects O
where
  lower(O.object_name) like '$motif'
order by 1";

system("sqlplus -s '/ as sysdba' <<!
$sql;
!");


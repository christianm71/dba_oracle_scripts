#!/usr/bin/perl -w

# ================================================================
# Christian MOISE
# get_object_definition.pl
# v1.0
# 2018/06/04
# affiche les DDL de creation d'un objet Oracle
# ================================================================

use strict;

my $script=$0;
$script=~s/.*\///;

# ==========================================================================================================================
sub help {
  print "
$script <object_owner>.<object_name> <object_type>
$script <tablespace_name> TABLESPACE
$script <username> USER

        [ -h -help ] : print this help

example : ./$script RTD.ATUSERS TABLE\n\n";
  exit(1);
}

# ==========================================================================================================================
if (scalar(@ARGV) == 0) { help(); }

my $object_owner="";
my $object_name=uc($ARGV[0] || "");
my $object_type=uc($ARGV[1] || "");

if (! $object_name) { help(); }

if ($object_name=~m/\./) {
  ($object_owner, my @other)=split(/\./, $object_name);
  $object_name=join(".", @other);
}

# ==========================================================================================================================
my $sql;
my $buffer;

if ((! $object_owner) || (! $object_type)) {
  $sql="set head off pagesize 0 feedback off echo off linesize 300
        col owner format a50
        col object_type format a50
        select owner, object_type from dba_objects where object_name='$object_name'";

  $buffer=`sqlplus -s '/ as sysdba' <<! 2>&1
  $sql;
  exit;
!`;
  chomp($buffer);
  #$buffer=~s/^\s+//s;
  #$buffer=~s/\s+$//s;

  my $arg_owner=$object_owner || "";
  my $arg_type=$object_type || "";

  foreach my $line (split(/\s*\n\s*/, $buffer)) {
    my ($owner, $type)=split(/\s+/, $line);

    if (! $object_owner) { $object_owner=$owner; }
    if (! $object_type)  { $object_type=$type;   }

    if ((! $arg_owner) && ($object_owner ne $owner)) {
      print "\nat least two owners found for object '$object_name': $object_owner, $owner\n\n";
      exit(1);
    }
    if ((! $arg_type) && ($object_type ne $type)) {
      print "\nat least two types found for object '$object_name': $object_type, $type\n\n";
      exit(1);
    }
  }
}

# ==========================================================================================================================
if (! $object_type) { help(); }

if (($object_type eq "DATABASE_LINK") || ($object_type eq "DBLINK")) { $object_type="DB_LINK"; }

$object_name=~s/\$/\\\$/g;
$object_owner=~s/\$/\\\$/g;

# ==========================================================================================================================
$sql="set head off pagesize 0 long 5000000 linesize 1000 verify off feedback off

col cmd format a1000\n\n";

if ($object_type eq "USER") {
  $sql=$sql . "select dbms_metadata.get_ddl('$object_type', '$object_name')||';' cmd from dual;
               select dbms_metadata.get_granted_ddl('ROLE_GRANT', '$object_name')||';' cmd from dual;
               select dbms_metadata.get_granted_ddl('OBJECT_GRANT', '$object_name')||';' cmd from dual;
               select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', '$object_name')||';' cmd from dual";
}
elsif ($object_type eq "TABLESPACE") {
  $sql=$sql . "select dbms_metadata.get_ddl('$object_type', '$object_name') cmd from dual";
}
else {
  $sql=$sql . "select dbms_metadata.get_ddl('$object_type', '$object_name', '$object_owner') cmd from dual";
}

$buffer=`sqlplus -s '/ as sysdba' <<! 2>&1
$sql;
exit;
!`;
chomp($buffer);

$buffer=~s/([^;\s])\s*$/$1;/s;
$buffer=~s/\n\s*ERROR:.*\n/\n/g;
$buffer=~s/\n\s*ORA-\d+.*//g;
$buffer=~s/([^;\s])\s*\n\s*(GRANT\s)/$1;\n$2/g;
$buffer=~s/([^;\s])\s*\n\s*(ALTER\s)/$1;\n$2/g;
$buffer=~s/(\sEND\s+$object_name\s*;)/$1\n\/\n/igs;
$buffer=~s/(\sEND\s*;)\s*$/$1\n\/\n/is;

print "$buffer\n\n";


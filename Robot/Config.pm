#!/usr/bin/perl -w

#package Robot::Config;
package Config;
require      Exporter;



our @ISA       = qw(Exporter);
our @EXPORT    = qw(load_paths load_vars);    # Symbols to be exported by default
#our @EXPORT=qw(say_hello);
#our @EXPORT_OK = qw();  # Symbols to be exported on request
our $VERSION   = 1.00;         # Version number

#my %db = (
#  user => 'root',
#  pass => 'secreto',
#  name => 'robot',
#  dbistring => 'DBI:mysql:',
#  events_tbl => 'eventos',
#);
#  string => $dbistring.$dbname,

#sub load_db {
#  return %db;
#}

sub load_paths {
  my %paths = (
    sites => 'sites',
    plugins => 'Plugins',
  );
  return %paths;
}

sub load_vars {
  my %vars = (
    cron => '*/5 * * * *',
    dbuser => 'root', # database stuff
    dbpass => 'secreto',
    dbname => 'robot',
    dbistring => 'DBI:mysql:',
    events_tbl => 'eventos',    
  );
  return %vars;
}

#sub say_hello {
#    print "Hi World!\n";
#}

1;

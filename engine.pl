#!/usr/bin/perl 
use strict;
use warnings;

use Data::Dumper;

use HTML::TokeParser;
use LWP::Simple;
use HTML::Entities;

use DBI;

# cron stuff
use Time::Local;
use Schedule::Cron::Events;

# log stuff
use Sys::Syslog qw( :DEFAULT setlogsock);

BEGIN { 
    unshift @INC, "./";
} 
use Robot::Config;

# el site que estoy probando...
my $testsite = 0;

# --- main program ---- 
# carga todas las configuraciones de  Config.pm - para evitar tener que tocar este archivo en lo absoluto
#my %db = Config->load_db();
my %path = Config->load_paths();
my %vars = Config->load_vars();

my $dirsites = $path{sites};

# log stuff
my $debug = 0;
my $programname = 'robot-engine';

# abre el directorio de sites, carga todos los archivos que hay ahi y los procesa ...
opendir(DIR, $dirsites) or die "can't opendir $dirsites: $!";
while (defined(my $file = readdir(DIR))) {
  # procesando "$dirname/$file" ...
  next if $file =~ /^\./; # avoiding . and .. (parent and current directories)
  next if $file =~ /~$/; # avoiding gedit backup files... :) ... hubiera sido mas rapido cargar solo los .ini :P
  if ($testsite) {
    next unless $file =~ /$testsite/;    
  }
  alert("procesando: $file\n");
  process_site($file);
}
closedir(DIR);
# --- /main program ---- 


# -- funciones que podrian ir en Functions.pm ---

sub process_site {
  my $site = shift(@_);
  my %result = load_config($site);
  if ($result{offline}) { next; }
  
  # cron stuff
  my $epochN = timelocal(localtime());
  my $cron = new Schedule::Cron::Events( $vars{cron},  Seconds => time() );
  my ($sec, $min, $hour, $day, $month, $year) = $cron->nextEvent;
  my $epoch = timelocal($sec, $min, $hour, $day, $month, $year);
  my $nextrun = $epoch - $epochN;
  my $cron1 = new Schedule::Cron::Events( $result{cron},  Seconds => time());
  ($sec, $min, $hour, $day, $month, $year) = $cron1->nextEvent;
  my $epoch1 = timelocal($sec, $min, $hour, $day, $month, $year);
  my $next1 = $epoch1 - $epochN;
  if (!($next1 <= $nextrun)) {
    # body...
    return 1;
  } 

  require "Robot/".$path{plugins}."/".$result{plugin}.".pm";
  my $url = $result{url};

  my @events = $result{plugin}->get_events($url);

  my $dbh = get_dbh(); 
  my $locationsql = "select id, title from location where title = '".$result{location}."'";
  
  my ($location_id, $location_title) = $dbh->selectrow_array($locationsql);
  if (!($location_id)) {
      my $sth = $dbh->prepare("INSERT INTO location (title) VALUES (?)");
      $sth->execute( $result{location} );
      $locationsql = "select id, title from location where title = '".$result{location}."'";
      ($location_id, $location_title) = $dbh->selectrow_array($locationsql);
  }

  
  if (!save_events($dbh,$location_id,@events)) {
    alert("error salvando en la db!\n");
    logit('debug', "Error saving in the database: ") if $debug;
  }
}  

sub get_dbh {
  my $dbh = DBI->connect($vars{dbistring}.$vars{dbname}, $vars{dbuser}, $vars{dbpass}, {'RaiseError' => 1});
  return $dbh;
}


# esta funcion recibe un mensaje y hace con el lo que tenga definido
# por ahora, lo imprime en consola pero se puede extender en el futuro.
sub alert {
  print "@_" if $debug;
}

sub load_config {
  my $site = shift(@_);
  my $cfgfile = "sites/$site";
  #  open(CONFIG, "< $cfgfile") or die "can't open $cfgfile: $!";
  open(CONFIG, "< $cfgfile") or 
       logit('err', "Error opening prog.conf: $!");
  my %config;
  my $key; my $value;
  while (<CONFIG>) {
      chomp;
      s/#.*//; # Remove comments
      s/^\s+//; # Remove opening whitespace
      s/\s+$//;  # Remove closing whitespace
      next unless length;
      my ($key, $value) = split(/\s*=\s*/, $_, 2);
      $config{$key} = $value;
  }
  if (!($config{cron})) {
    $config{cron} = $vars{cron};
  }
  
  close(CONFIG);
  return %config;
}


# -- /funciones que podrian ir en Functions.pm ---




# ---   Database functions --------------
# recibe un array of hashes con los eventos y lo guarda en la base de datos.
#  my @events = shift(@_);

  
sub save_events{
  my ($dbh,$location_id,@events) = @_;
  my $query; # el query del insert, lo declaro aca para evitar uno por insert    
  for my $href ( @events ) {
    my $sqlcols = '';
    my $sqlvalues = '';
    my @cols; my @values;
    for my $field ( keys %$href ) {
      $href->{$field} =~ s/\'/\"/g;
      push @cols, $field;
      push @values, $href->{$field};
    }
    push @cols, 'location';
    push @values, $location_id;
    my $columns = join ",",@cols;
    my $values = join "','",@values;

    my $sql = "SELECT * FROM ".$vars{events_tbl}." WHERE startDate = '".$href->{startDate}."' AND location = '".$location_id."'";
    my $sth = $dbh->prepare($sql);
    if (!$sth) {
        logit('debug', "Error opening database: " . $dbh->errstr ) if $debug;
        die "Error:" . $dbh->errstr . "\n";
    }
    if (!$sth->execute) {
        logit('debug', "Error opening database: " . $dbh->errstr ) if $debug;
        die "Error:" . $sth->errstr . "\n";
    } else {
      if ($sth->rows()) {
        alert(".");
      } else {
        alert("*");
        $query = "INSERT INTO ".$vars{events_tbl}." (".$columns.") VALUES ('".$values."')";
        logit('debug', "Insertando registro !! " . $query ) if $debug;
        $sth = $dbh->prepare($query);
        $sth->execute;
      }
    }
  $sth->finish();
  }
  # close connection  
  $dbh->disconnect();
  return 1;
}

# devuelve TRUE si hay resultados, FALSE si no
# Can't call method "prepare" on unblessed reference at engine.pl line 201.
# me da error .... la paso para la function ...
sub select_rows {
#  my $dbh = DBI->connect($dbstring, $dbuser, $dbpass, {'RaiseError' => 1});
  my ($dbh,$sql) = @_;
  my $sth = $dbh->prepare($sql);
  if (!$sth) {
      die "Error:" . $dbh->errstr . "\n";
  }
  if (!$sth->execute) {
      die "Error:" . $sth->errstr . "\n";
  } else {
    if ($sth->rows()) {
      # hay rows...
      return 1;
    } else {
      # else... cero rows ....
      return 0;
    }
  #  return 1;
  }
}
# ---   /Database functions --------------

sub logit {
    my ($priority, $msg) = @_; 
    return 0 unless ($priority =~ /info|err|debug/);
    setlogsock('unix');
    # $programname is assumed to be a global.  Also log the PID
    # and to CONSole if there's a problem.  Use facility 'user'.
    openlog($programname, 'pid,cons', 'user');
    syslog($priority, $msg);
    closelog();
    return 1;
}


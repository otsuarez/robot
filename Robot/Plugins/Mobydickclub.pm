package Mobydickclub;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    # Symbols to be exported by default

#####################
# $event{x}
# 
# title
# startDate
# price
# description
# 
#####################

my $debug = 1;

#use strict;
use HTML::TokeParser;
use LWP::Simple;
use HTML::Entities;
#use Encode;
use HTML::TokeParser::Simple;

if ($debug) {
  use Data::Dumper;
}

sub get_events {
  my $sarasa = shift;
  my $url = shift;
  my $data = LWP::Simple::get($url) or die $!;
  my $p = HTML::TokeParser::Simple->new(\$data);
  my $token;
  my $price ='';
  my $title = '';
  my $day; my $year; my $month; my $titulonormal; my $dia;
  my %event = ();
  my $event = {};
  my @events;
  my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag,);
  my $preciotaquilla;
  my $description = '';
  my $hora;
  
  # este tiene dos niveles, una pagina que enlaza a otra con los detalles del evento
  # probando primero buscar los span (ignorando los tr)
  for (my $i = 0; $i < 4; $i++) {
    $token = $p->get_tag("table");
  } # hay tres tablas iniciales
  $token = $p->get_tag('td');
  if ($token->[1]{class} and ($token->[1]{class} =~ /^titulonormal$/)) {
    $titulonormal = $p->get_trimmed_text('/td');
  }
  ($month,$year) = $titulonormal =~ m/(\w+)\s+\|\s+(\d+)/g;
  $month = get_month($month);  
  
  while ($token = $p->get_tag("table")) {  
    $token = $p->get_tag('td');
    $description = '';
    if (!$token->[1]{align}) {  next; }
    if ($token->[1]{class} and ($token->[1]{class} =~ /^arial10grisclaro$/)) {    
      $token = $p->get_tag('span');
      $dia = $p->get_trimmed_text('br');
    } elsif ($token->[1]{class} and ($token->[1]{class} =~ /^fechas$/)) { 
      $dia = $p->get_trimmed_text('br');
    } 
    $token = $p->get_tag('img');
    $token = $p->get_tag('strong');
    $titulo = encode_entities($p->get_trimmed_text('/strong'));
    $token = $p->get_tag('br');
    $token = $p->get_token;
    if ($token->[0] =~ /T/) { 
      $precio = $token->[1];
      $precio =~ s/^\s+//;
    }
    $token = $p->get_token;
    $token = $p->get_token;
    $preciotaquilla = '';
    if ($token->[0] =~ /T/) { 
      $preciotaquilla = $token->[1];
      $preciotaquilla =~ s/^\s+//;
    }
    $token = $p->get_token;
    if (($token->[0] =~ /S/) and ($token->[1] =~ /br/)) {   
      $token = $p->get_token;
    }
#    PUERTAS 21H. TAQUILLA: 8 EUROS 
#    PUERTAS 21:00 H. ANT. (SNAPO): 6 EUROS 
#    PUERTAS 21:00 H. ANT. (RED TICKTACKTICKET): 17 EUROS 
    $precio =~ m/.*UERTAS\s+(\d.*)H\.(.*)$/g;
    $hora = $1;
    $price = $2;
    $hora =~ s/\s$//;
    if ($preciotaquilla =~ /\w/) {
      $preciotaquilla .= ", " . $price;
      $price = $preciotaquilla;
    } else {
      $price =~ s/^\s+//g;
    }
    $dia =~ m/(\w.*)\s+(\d+)/g;
    my $dia = $2; # esta es!
    if (!($hora =~ /:/)) { $hora .=  ":00";  } # le adiciono minutos para respetar el formato.
    $event{price} = $price;
    $event{title} = $titulo;
    $event{startDate} = $year . "-" . $month . "-" . $dia . " " . $hora;
    
    
    if ($token->[0] =~ /T/) { # parseando description
      $description = $token->[1];
      $description =~ s/^\s+//;
      
      if (!($description =~ /\w/)) {
        $token = $p->get_token;
        if ($token->[2]{class} and ($token->[2]{class} =~ /^arial10grisclaro$/)) {   
          $description = encode_entities($p->get_trimmed_text('/span'));
        } else {
          $description = '';        
        }
      }
    } elsif ($token->[2]{class} and ($token->[2]{class} =~ /^arial10grisclaro$/)) { 
      $description = encode_entities($p->get_trimmed_text('br'));
    } elsif (($token->[0] =~ /E/) and ($token->[1] =~ /span/)) {   
      $token = $p->get_token;
      $token = $p->get_token;
      if ($token->[0] =~ /T/) { # tengo un description!
        $description = encode_entities($token->[1]);
        $description =~ s/^\s+//;
      }
    } 
  $event{description} = $description;
  push @events, {%event};
  } # end while get p
  return @events;
} # end of get_events

#################################################################
#          
#   get_month
#   recibe un mes en letra y devuelve el numero correspondiente
#   ENERO -> 1, AGOSTO -> 8 
#          
#################################################################
sub get_month {
  my $mmraw = shift;
  my $mm; my $result = '0';
  if ($mmraw =~ m/enero/i) {
     $result = '01';    
  } elsif ($mmraw =~ m/febrero/i) {
     $result = '02';
  } elsif ($mmraw =~ m/marzo/i) {
     $result = '03';
  } elsif ($mmraw =~ m/abril/i) {
     $result = '04';
  } elsif ($mmraw =~ m/mayo/i) {
     $result = '05';
  } elsif ($mmraw =~ m/junio/i) {
     $result = '06';
  } elsif ($mmraw =~ m/julio/i) {
     $result = '07';
  } elsif ($mmraw =~ m/agosto/i) {
     $result = '08';
  } elsif ($mmraw =~ m/septiembre/i) {
     $result = '09';
  } elsif ($mmraw =~ m/octubre/i) {
     $result = '10';
  } elsif ($mmraw =~ m/noviembre/i) {
     $result = '11';
  } elsif ($mmraw =~ m/diciembre/i) {
     $result = '12';
  } else {
    $result = '00';
  }
  return $result;
}

1;

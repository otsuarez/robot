package Salariviera;
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
# image
# puntosventa
# ventalink
#
#####################



my $debug = 1;

use HTML::TokeParser;
use LWP::Simple;
use HTML::Entities;
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
  my $hora; my $dia; my $year;
  
  # muy basico, un div id=eventos y dentro, div class=eventos con los datos
  # probando primero buscar los span (ignorando los tr)
  while ($token = $p->get_tag("div")) {  
    if ($token->[1]{class} and ($token->[1]{class} =~ /^eventos/)) {   # found one!
      $token = $p->get_tag('img');
      $event{image} = $url . $token->[1]{src};
      $event{title} = $p->get_trimmed_text('/h2');
      $fecha = $p->get_trimmed_text('/p');
      $p->get_token;
      $hora = $p->get_trimmed_text('/p');
      $token = $p->get_token;
      $token = $p->get_token; # tengo que parsear uno a uno porque el get_trimmed_text me caga con el simbolo de euro
      $token = $p->get_token; #empty text
      $token = $p->get_token; # start p class=precio
      $precio = decode_entities($token->[1]);
      $event{price} = $precio;
      $token = $p->get_tag('a');
      $event{ventalink} = $token->[1]{href};
      $hora =~ s/Apertura de puertas: (\d+:\d+).*/$1/g;
      $fecha =~ s/.*,\s+(.*)/$1/g;
      ($dia,$month,$year) = $fecha =~ m/(\d+)\s+de\s+(\w+)\s+de\s+(\d+)/g;
      $month = get_month($month);
      $event{startDate} = $year . "-" . $month . "-" . $dia . " " . $hora;
      push @events, {%event};
    }   
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

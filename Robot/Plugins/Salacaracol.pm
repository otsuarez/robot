package Salacaracol;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    # Symbols to be exported by default

#####################
# $event{x}
# 
# title
# description
# startDate
# puntosventa
# price
# image
# 
# artistlink
#####################

use Data::Dumper;


sub get_events {
  use HTML::TokeParser;
  use LWP::Simple;
  use HTML::Entities;
  use HTML::TokeParser::Simple;
  my $sarasa = shift;
  my $url = shift;
    
  my $data = LWP::Simple::get($url) or die $!;
  my $p = HTML::TokeParser::Simple->new(\$data);

  my $mmyy; # month year. in a iso friendly format, e.g.: 2009-08, 2009-07
  my $mmyyraw; #month year: original format for each month. e.g: agosto   2009, Julio   2009

  my $price ='';
  my $title = '';
  my $day;
  my %event;
  my @events;
  my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag);
  
  # salacaracol
  my $fecha; my $hora; my $startDate; my $dia;

  # la pagina actual es div.contenedor -> div.emtpy -> div (cabecera img) -> div.fecha y ahi arranca la cosa
  # buscar el div.fecha y parsear a partir de ahi

  #  primero buscar los span (ignorando los tr)
  while (my $token = $p->get_tag("div")) {
    if ($token->[1]{id} and ($token->[1]{id} =~ /^fecha/)) {    
      $fecha = encode_entities($p->get_trimmed_text("/div"));
      # hay dos formatos de fecha:
      # JUEVES, 02 DE JULIO 2009
      # VIERNES, 10.07.2009
      $fecha =~ s/.*,//g;
      if ($fecha =~ m/(\d*)\.(\d+)\.(\d+)/) {
        $dia = $3 . "-" . $2 . "-" . $1;
      } elsif  ($fecha =~ m/(\d+)\s+DE\s+(\w+)\s+(\d+)/) {
        # 2009-08-29 21:30:00 
        $dia = $3 . "-" . get_month($2) . "-" . $1;
      }
      $token =  $p->get_tag('div');
      $token =  $p->get_tag('div');
      # title
      $title = $p->get_trimmed_text("/div");
      $event{title} = $title;      
      $token =  $p->get_tag('div');
      if ($token->[1]{id} and ($token->[1]{id} =~ /^hora/)) {
        $hora = $p->get_trimmed_text("/div");
        $hora =~ s/(\d+):(\d+).*/$1:$2/g;
      }
      $startDate = $dia . " " . $hora . ":00";
      $event{startDate} = $startDate; 
      $token =  $p->get_tag('table');
      $token =  $p->get_tag('tr');
      $token =  $p->get_tag('td');
      $token =  $p->get_tag('div');      
      $token =  $p->get_tag('img');            
      if ($token->[0] =~ /img/) { # algunos no tienen el a, van directo al img
        $url =~ s/^(.*\/)\w+\.\w+$/$1/;
        $event{image} = $url . $token->[1]{src} || "--";   
      }
      $token =  $p->get_tag('tr');
      $token =  $p->get_tag('td');
      $token =  $p->get_tag('p');
      $event{price} = $p->get_trimmed_text("/p");
      $token =  $p->get_tag('p');


      $event{puntosventa} = $p->get_trimmed_text("/p");
      $token =  $p->get_tag('p');

      $event{description} = $p->get_trimmed_text("/td");
      $token =  $p->get_tag('div');      
      
      ####################
      # no se utilizan pero aqui quedan parseados ...
      ####################
      if ($token->[1]{id} and ($token->[1]{id} =~ /^links/)) {
        my $artistlinks = $p->get_trimmed_text("/div");

      push @events, {%event};
      }      
    } # if div.fecha
  } # end while

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

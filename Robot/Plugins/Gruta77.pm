package Gruta77;
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
my $weburl;

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

  
  my $nextpage;
  my $pager;
  
  my $token;
  my $price =''; my $title = '';

  my %event = (); my $event = {}; my @events = ();
  my $description = '';
  
  my $hora;  my $mes;
  my $day; my $year; my $month; my $dia;
  my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag,);
  
  # cuatro niveles con paginacion
  # pagina inicial - estan las paginas por mes con los eventos
  # pagina de eventos - title, price, startDate
  # pagina del evento - clasification
  # pagina del artista - description, image
  
  $url =~ s/^(.*\/)\w+\.\w+$/$1/;
  $weburl = $url;
  #########################################
  #   empiezo  ....
  #   
  my $i = 0;
  while ($token = $p->get_tag("span")) {
    #   voy a procesar solo los tres primeros meses pues luego 
    #   aun no tienen precio la mayoria de los eventos.
    if ($i >= 3) { next; }
    if ($token->[1]{class} and ($token->[1]{class} =~ /^blancorojo/)) {
      $token = $p->get_tag('a');
      $mesurl = $weburl.$token->[1]{href};
      # esta funcion me retorna un AoH que debo ir sumando.
      push @events, process_page($mesurl,0);
      $i++;
    }
  }
  #  
  #   termino  ...
  #########################################
  return @events;
} # end of get_events


sub process_page {
  my $url = shift;
  my $paginatorsgt = shift;
  %event = (); # arranco con un H limpio
  @events = ();

  if (!($paginatorsgt)) {
    $fecha = $url;
    $fecha =~ s/.*=(.*)/$1/g;
    ($year,$mes) = $fecha =~ m/(\d+)-(\d+)/g;
  } else {
    $fecha = $url;
    $fecha =~ s/.*=(.*)\&pagina.*/$1/g;
    ($year,$mes) = $fecha =~ m/(\d+)-(\d+)/g;  
  }

  
  my $data = LWP::Simple::get($url) or die $!;
  my $p = HTML::TokeParser::Simple->new(\$data);
  
  my $token = $p->get_tag('ul');
  $token = $p->get_tag('ul');
  $token = $p->get_tag('a');  
  if ($token->[1]{class} and ($token->[1]{class} =~ /^paginator_sgt/)) {
    $nextpage = $token->[1]{href};  
    process_page($weburl.$nextpage,1);
  }  

  #########################################
  #   empiezo a procesar los eventos ....
  #
  while ($token = $p->get_tag("li")) {  
    %event = ();
    $fecha = $p->get_trimmed_text('/span');
    # Viernes 17 de Julio
    
    $fecha =~ s/(\w+)\s+(\d+)\s+de\s+\w+/$2/g;

    $token = $p->get_tag('span');
    $hora = $p->get_trimmed_text('/span');
    $hora =~ s/(\d.*:\d+).*/$1/g;
    $token = $p->get_tag('a');
    my $details =  $token->[1]{href}; 
    $titulo = $p->get_trimmed_text('/b');
    $url =~ s/^(.*\/)\w+\.\w+$/$1/;
    $event{title} = $titulo;
    $event{startDate} = $year . "-" . $mes . "-" . $fecha . " " . $hora;
    
    $token = $p->get_tag('span');
    $event{price} = $p->get_trimmed_text('/span');
    $event{detailsurl} = $weburl.$details;
    get_event_details(\%event);
    push @events, {%event};
  }
  return @events;
  #  
  #   termino de procesar los eventos ....
  #########################################
}

#########################################
#   pagina del evento ....              #
#                                       #
#########################################
sub get_event_details {
  my $url = $event{detailsurl};
  my $data = LWP::Simple::get($url) or die $!;
  my $p = HTML::TokeParser::Simple->new(\$data);
  while ($token = $p->get_tag("div")) {
    if ($token->[1]{class} and ($token->[1]{class} =~ /^parafos/)) {
      $token = $p->get_tag('font');
      $event{clasification} = $p->get_trimmed_text('/font');
      $token = $p->get_tag('a');
      if ($token->[0] =~ /a/) {
        if ($token->[1]{class} and ($token->[1]{class} =~ /^rojo/)) { # tengo un enlace a la banda
          $event{bandadetailurl} = $weburl.$token->[1]{href};
          get_artist_details(\%event);      
      }
    }
    } # end del if de parafos
  } # end del while de los div  
}
#                                       #
#                                       #
#########################################



#########################################
#   pagina del artista ....             #
#                                       #
#########################################
sub get_artist_details {
#  my $url = shift;
  my $url = $event{bandadetailurl};
  my $data = LWP::Simple::get($url) or die $!;
  utf8::decode($data);
  my $p = HTML::TokeParser::Simple->new(\$data);
  #  $url =~ s/^(.*\/)\w+\.\w+$/$1/;  # transformo la url para formar la url de image
  while ($token = $p->get_tag("div")) {
    if ($token->[1]{class} and ($token->[1]{class} =~ /^contenido/)) {
      $token = $p->get_tag('img');
      $event{image} = $weburl . $token->[1]{src}  || "--";    
    while ($token = $p->get_tag("div")) {
      if ($token->[1]{class} and ($token->[1]{class} =~ /^parafos/)) {
        $token = $p->get_token;
        $token = $p->get_token;
        if ($token->[2]{class} and ($token->[2]{class} =~ /^parafos/)) {
          next;
        }
        if ($token->[2]{class} and ($token->[2]{class} =~ /^size_150/)) {
          $token = $p->get_tag("/h2");
          $event{description} = $p->get_trimmed_text('/div');
        }
      }    
    }
    } # end del if de parafos
  } # end del while de los div  
}
#                                       #
#                                       #
#########################################


1;

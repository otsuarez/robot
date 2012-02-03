package Elsolmad;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    # Symbols to be exported by default

#####################
# $event{x}
# 
# title
# startDate
# puntosventa
# price
# image
# description
# 
#####################

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

  my $price ='';
  my $title = '';
  my $day;
  my %event = ();
  my $event = {};
  my @events;
  my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag, $description);
  
  # este tiene dos niveles, una pagina que enlaza a otra con los detalles del evento
  # probando primero buscar los span (ignorando los tr)
  while (my $token = $p->get_tag("b")) {  
    if ($token->[1]{class} and ($token->[1]{class} =~ /^concierto$/)) {    
      $token = $p->get_tag('a');
      my $hora; my $startDate;
      $event{title} = $token->[1]{title};
      my $eventurl  = $token->[1]{href};
      $url =~ s/^(.*\/)\w+\.\w+$/$1/;
      my $geturl = $url.$eventurl;
      ($event{price},$event{puntosventa},$event{startDate},$event{description}) = get_event($geturl);
      push @events, {%event};
    } # end if conciertos 
  } # end while get p
  return @events;
} # end of get_events


sub get_event {
      $eventurl = shift;
      my $eventdata = LWP::Simple::get($eventurl) or die $!;
      my $pp = HTML::TokeParser::Simple->new(\$eventdata);
      my $tag = $pp->get_tag('p');
      if ($tag->[1]{class} and ($tag->[1]{class} =~ /^titulo$/)) {
          $tag = $pp->get_tag('p');
        }
        if ($tag->[1]{class} and ($tag->[1]{class} =~ /^titulotexto$/)) {
          $titulotexto = $pp->get_trimmed_text('/p');         
          if ($titulotexto =~ m/Fecha/) {
            $titulotexto =~ m/(\d+)-(\d+)-(\d+)/;
            $fecha = $3 . "-" . $2 . "-" . $1;
          $tag = $pp->get_tag('p');
          }
        }
        if ($tag->[1]{class} and ($tag->[1]{class} =~ /^titulotexto$/)) {
          $titulotexto = $pp->get_trimmed_text('/p');         
          if ($titulotexto =~ m/Hora/) {
            $titulotexto =~ m/.*\s+(\d+:\d+)/;
            $hora = $1;            
          }
        }
        $startDate = $fecha . ' ' . $hora;
        $tag = $pp->get_token; #cierro el /p
        $tag = $pp->get_token; # un T empty
        $tag = $pp->get_token; # un T empty
        # tengo que entrar en un if
        # puede ser un <p class="texto"> con el price/puntosventa
        # o puede que no ... - entradas agotadas e.g.
        if ($tag->[2]{class} and ($tag->[2]{class} =~ /^texto$/)) {
          my $texto = $pp->get_trimmed_text('/p');         
          if ($texto =~ m/Precio: (.*)/) {
            $precio = $1;
          }
          $pp->get_tag('p');
          $texto = $pp->get_trimmed_text('/p');
          if ($texto =~ m/Punto de venta: (.*)/) {
            # aqui tenemos varias posibilidades:
            # 15 � Anticipada en TICKETMASTER
            # 12 � +gastos de emisi�n en TICKETMASTER
            # Taquilla 7� con cerveza o refresco.
            # Taquilla.
            # o nada si el evento tiene las entradas agotadas...
            my $pv = $1;
            if ($pv =~ m/(.*) en (.*)/) {
              $precio .= ', ' . $1;
              $puntosventa = $2;
            } elsif ($pv =~ m/Taquilla/){
              $puntosventa = 'Taquilla';
            }
          }       
        $tag = $pp->get_token;     
        } else { # si no tiene precio, tengo que setearle el precio como cero ;)
          $precio = '0';
          $puntosventa = '';
        } # enf if <p class="texto"> el precio y el puntosventa
        $tag = $pp->get_token; #  /p
        $tag = $pp->get_token; # un T empty
        if ($tag->[0] =~ 'E') {
          $tag = $pp->get_token; # y dejo atras ese ending td del precio
          $tag = $pp->get_token; # un T empty
        } # and we're back!
        $pp->get_tag('/table'); # primer table
        $pp->get_tag('/table');
        $tag = $pp->get_token;
        $tag = $pp->get_token;
        if ($tag->[2]{class} and ($tag->[2]{class} =~ /^texto$/)) {
          $pp->get_tag('/p'); # me salto el label
          $tag = $pp->get_token;
        } else {
          $description = NULL;          
        }
        # ahora viene textopie
  return ($precio,$puntosventa,$startDate,$description);        
}


1;

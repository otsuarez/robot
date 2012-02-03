package BarracudasRockBar;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    


use Encode;
use Data::Dumper;
use HTML::Entities;

sub get_events {
    use HTML::TokeParser;
    use LWP::Simple;
    my $sarasa = shift;
    my $url = shift;
    $url =~ m/(http:\/\/\w.*\/).*/g;
    my $siteurl = $1;
    
    my $data = LWP::Simple::get($url) or die $!;
    my $p = HTML::TokeParser->new(\$data);

    my $price ='';
    my $title = '';
    my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag) = '';
    my $yy; my $mm; my $dd; my $hh; my $mn;
    my $date; my $time;
    my %event = ();
    my @events;
    my $i = 0;
    
    my $token;
    my $bandadetailsurl;
    
    $token = $p->get_tag("table");
    $token = $p->get_tag("table");
    $token = $p->get_tag("table");
    while ($token = $p->get_tag("tr")) {

      if ($token->[1]{bgcolor} and ($token->[1]{bgcolor} =~ /^#003333/)) {    
        $token = $p->get_tag('div'); # dia de la semana  
        $token = $p->get_tag('span'); # dia del mes
        $token = $p->get_tag('span');
        $token = $p->get_token;
        $fecha = $token->[1];
        $fecha =~ /(\w+)\s+(\w+)/;
        $mes = $1; $year = $2;
      } 
      
      if ($token->[1]{bgcolor} and ($token->[1]{bgcolor} =~ /^#000000/)) {
        $titulo = $bandadetailsurl = $image = '';
        $token = $p->get_tag('td'); # dia de la semana  
        $token = $p->get_tag('td'); # dia del mes
        $token = $p->get_tag('font');
        $dia = $p->get_trimmed_text('/font');
        $token = $p->get_tag('td'); # dia de la semana  
#        $token = $p->get_token; # p align center en uno y T vacio el resto
#        $token = $p->get_token;
        while ((!($token->[2] =~ /<\/tr>/))) { # (!($token->[0] =~ /E/)) && 
          $token = $p->get_token;
          next if ($token->[0] =~ /E/);
          next if (($token->[0] =~ /T/) && (!($token->[1] =~ /\w/)));
          next if ($token->[1] =~ /blockquote/);
          next if ($token->[1] =~ /div/);
          next if ($token->[1] =~ /b/);
          next if ($token->[1] =~ /font/);
          next if ($token->[1] =~ /p/);
          if (($token->[0] =~ /T/)) {
            $titulo .= $token->[1];
            next;
          }
          if (($token->[1] =~ /a/)) {
            next if $bandadetailsurl =~ $token->[2]{href}; # para el caso en que repiten la misma url
            my $tempurl = $token->[2]{href};
            if (!($tempurl =~ /htm/)) { $tempurl = $tempurl . ".htm" }
            $bandadetailsurl .= $tempurl . "|";
            next;
          }    
        }
        $titulo  =~ s/\n//g; 
        $titulo = decode_entities($titulo);
        $event{title} = $titulo;
        
        $bandadetailsurl =~ s/\|$//; # le quito el | que sobra al final
        my $detailsurl;
        if ((!($bandadetailsurl =~ /\w/))) {
           $event{description} = NULL; # no tengo details ...  
           $event{image} = NULL; # ni image ...
        } else {
          $event{description} = NULL;
          if ($bandadetailsurl =~ /\|/) {
            my @values = split('\|', $bandadetailsurl);
            my %details = ();
            my @pics = ();

            # adiciono todos los descriptions y asi el contenido puede quedar indexado
            foreach my $val (@values) {
              $detailsurl = $siteurl.$val;
              my $bandadetailsdata = LWP::Simple::get($detailsurl) or die $!;
              $event{description} .= get_description($bandadetailsdata) . "\n<br />";
              push @pics, get_image($bandadetailsdata);
            }
            
            foreach my $pic (@pics) {
              if ($pic) {
                $event{image} = $siteurl.$pic;
                last; # tomo la primera imagen que encuentre
              }
              $event{image} = NULL; # si no encontre ninguna ...
            }
          } else {
            $detailsurl = $siteurl.$bandadetailsurl;
            my $bandadetailsdata = LWP::Simple::get($detailsurl) or die $!;
            $event{description} = get_description($bandadetailsdata);
            if ($img = get_image($bandadetailsdata)) {
              $event{image} = $siteurl.$img;            
            } else {
              $event{image} = NULL;
            }
          }
        }
        if ($dia =~ /^\d$/) {
          $dia = "0".$dia;
        }
        $event{startDate} = $year . "-" . get_month($mes) . "-" . $dia . " 22:00:00";
        $event{price} = 'n/a';
      } 
        next if (!($event{title} =~ /\w/));
        push @events, {%event};
        $i++;
    } # end while tr
    return @events;
}

sub get_description {
  my $data = shift;
  my $p = HTML::TokeParser->new(\$data);
  my $token;
  $token = $p->get_tag('img');
  $token = $p->get_tag('td');
  my $description = $p->get_trimmed_text('/table');
}

sub get_image {
  my $data = shift;
  my $p = HTML::TokeParser->new(\$data);
  my $token; my $img;
  $token = $p->get_tag('img');
  if ($token->[1]{src}) {
    $img = $token->[1]{src};
  } else {
    $img = NULL;
  }
  return $img;
}

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

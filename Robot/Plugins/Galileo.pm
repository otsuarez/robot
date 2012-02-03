package Galileo;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    # Symbols to be exported by default



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
  my $day; my $startDate;
  my %event;
  my @events;
  my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag);

  # la pagina actual es tr -> span -> div.img-shadow -> tr -> span -> tr -> div.img-shadow
  # buscar el tr -> span -> div.img-shadow

  #  primero buscar los span (ignorando los tr)
  while (my $token = $p->get_tag("span")) {

    if ($token->[1]{class} and ($token->[1]{class} =~ /description/)) {  
      my $mmyyraw = encode_entities($p->get_trimmed_text("/strong"));
      $mmyyraw  =~ s/&nbsp;/ /g;
      if (($mmyy =  get_mmyy($mmyyraw)) =~ /0000-00/) { 
        # "fecha no reconocida\n"; 
        next; 
      }        
      while (my $tag = $p->get_token()) {
        if ($tag->is_start_tag('span')) { 
          $mmyyraw = encode_entities($p->get_trimmed_text("/strong"));
          $mmyyraw  =~ s/&nbsp;/ /g;
          if (($mmyy =  get_mmyy($mmyyraw)) =~ /0000-00/) { 
            # "fecha no reconocida\n"; 
            next; 
          }        
        }

#        Use of uninitialized value in join or string at engine.pl line 238.
#        Use of uninitialized value in concatenation (.) or string at engine.pl line 240.
        if (($tag->is_start_tag('div')) and ($tag->[2]{class} =~ /img-shadow2/)) { 
          $fecha = encode_entities($p->get_trimmed_text("/strong"));
		      $fecha  =~ s/&nbsp;/ /g;
		      $fecha =~ m/(\w.+)\s+(\d+)/;
		      $day = $2;
		      my $hora = encode_entities($p->get_trimmed_text("br"));
		      $hora  =~ s/&nbsp;//g;
		      $hora  =~ s/\-//g;
		      $hora  =~ s/[\s|\.]//g;
		      $hora =~ s/h$//;		   
		      $tag = $p->get_tag('br');		

		      my $clasificacion = encode_entities($p->get_trimmed_text("br"));   
		      $event{clasification} = $clasificacion; 

          $tag = $p->get_token; # texto de la clasificacion
          $tag = $p->get_token; # texto de la clasificacion

          $tag = $p->get_token; # el br que viene detras de la clasificacion
          $tag = $p->get_token; # el br que le sigue
          if ($tag->[0] =~ /T/) { $tag = $p->get_token; }

          # el primer bloque tiene un solo br, el segundo tiene dos...
          # si hay un tag, vamos a procesarlo
          if ($tag->[1] =~ /a/) {
            my $title = $tag->[2]{title};
            my $parser = HTML::TokeParser->new(\$title);
            my $text = '';
            while (my $tkn = $parser->get_token) {
                next if $tkn->[1] =~ /br/;
                next if $tkn->[1] eq 'b';
                next if $tkn->[1] =~ /gina web/;
                next if $tkn->[1] =~ /^\s+/;
                next if $tkn->[0] eq 'E';
                if ($tkn->[1] eq 'img'){
                  $img = $tkn->[2]{src} || "--";
                  $img =~ s/\/\//\//g;
                  $event{image}= $img;
                  next;
                }
                if ($tkn->[1] eq 'a'){
                  next;
                }
                if ($tkn->[0] =~ /T/) { 
                    if (!($tkn->[1] =~ /[[^a-z]|\s+]/)) {
                      $text .= ''; 
                    } else {
                      $text .= encode_entities($tkn->[1]); 
                    }   
                    $event{description} = $text;
                }
            }
          } elsif ($tag->[1] =~ /img/) { # algunos no tienen el a, van directo al img
            $event{image} = $tag->[2]{src} || "--";   
          }
          # salgo del img y me voy para el div con el titulo
		      $tag = $p->get_tag('div');	
          $titulo = encode_entities($p->get_trimmed_text("/strong"));
		      $titulo  =~ s/&nbsp;/ /g;
		      $day =~ s/^(\d{1})$/0$1/;
		      $startDate = $mmyy."-".$day." ".$hora.":00";
		      $event{startDate} = $startDate;
		      $event{title} = $titulo;
          $price = encode_entities($p->get_trimmed_text("/div"));
		      $price  =~ s/^\w+\s+/ /g;  
		      $price  =~ m/(\d+)/;  
		      $price = $1;
          $event{price} = $price;
          push @events, { %event };

        } # end del if del img-shadow
		      #    title, subtitle, description, puntosventa, ventalink, image, price, location, startDate DATETIME NOT NULL default '0000-00-00',
      } 
    } # end if span description
  } # end while span

  return @events;
} # end of get_events



sub get_mmyy {
  my $mmyyraw = shift;
  $mmyyraw =~ m/\s+(\w+)\s+(\d+)/;
  my $mmraw = $1; 
  my $yy = $2; 
  my $mm; my $result = '0';
  if ($mmraw =~ m/enero/i) {
     $result = "$yy-".'01';    
  } elsif ($mmraw =~ m/febrero/i) {
     $result = "$yy-".'02';
  } elsif ($mmraw =~ m/marzo/i) {
     $result = "$yy-".'03';
  } elsif ($mmraw =~ m/abril/i) {
     $result = "$yy-".'04';
  } elsif ($mmraw =~ m/mayo/i) {
     $result = "$yy-".'05';
  } elsif ($mmraw =~ m/junio/i) {
     $result = "$yy-".'06';
  } elsif ($mmraw =~ m/julio/i) {
     $result = "$yy-".'07';
  } elsif ($mmraw =~ m/agosto/i) {
     $result = "$yy-".'08';
  } elsif ($mmraw =~ m/septiembre/i) {
     $result = "$yy-".'09';
  } elsif ($mmraw =~ m/octubre/i) {
     $result = "$yy-".'10';
  } elsif ($mmraw =~ m/noviembre/i) {
     $result = "$yy-".'11';
  } elsif ($mmraw =~ m/diciembre/i) {
     $result = "$yy-".'12';
  } else {
    $result = '0000-00';
  }
  return $result;
}

1;

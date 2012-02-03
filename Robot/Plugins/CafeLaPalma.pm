package CafeLaPalma;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    

if ($debug) {
  use Data::Dumper;
}

binmode(STDOUT, ":utf8"); 

my $i = 0;
my @events = ();

sub get_events {
  use LWP::Simple;
  use HTML::TokeParser;
  use Encode;

  my $sarasa = shift;
  my $url = shift;

  my %event = (); # arranco con un H limpio
  my @pageevents = ();

  my $token; my $trtoken;

  my $dia; my $fecha; my $foto; my $evento; my $grupos; my $inicio; my $precio; my $hora; my $diahora;
  my $puntosventa; my $ventalink; my $descripcion; my $bandadetailurl; my $fotofile;
  my $weburl = 'http://www.cafelapalma.com';
  my $nexturl = '';

  my $hora;
  my $data = LWP::Simple::get($url) or die $!;
  my $p = HTML::TokeParser->new(\$data);

  while ($token = $p->get_tag("table")) {
    #   voy a procesar solo los dos primeros meses pues luego 
    #   aun no tienen precio la mayoria de los eventos.  

    # table mesSiguiente
    if ($token->[1]{width} and ($token->[1]{width} =~ /^14%/)) { 
      $token = $p->get_tag('a');
      my $nextmonth = $token->[1]{href};
      $nextmonth =~ /javascript:mesSiguiente\('(\d+)','(\d+)'\)/;
      my $year = $2; my $month = $1;
      if ($month == '12') { $year++; $month = 1; } else { $month++; }
      $nexturl = $weburl."/conciertos.asp?month=" . $month . "&year=" . $year;
      $i++;
    }
    # table mes de la paginabinmode(STDOUT, ":utf8"); 
    if ($token->[1]{width} and ($token->[1]{width} =~ /^76%/)) {
      $token = $p->get_tag('strong');
      $token = $p->get_token;
      $fecha = $token->[1];
      $fecha =~ m/(\w+)&nbsp;&nbsp;\s+(\d+)$/;
      $mes = $1; $year = $2;
      $mes = get_month($mes);
    } 
    if ($token->[1]{width} and ($token->[1]{width} =~ /^770px/)) { # arranca la tabla de eventos
      while ($token = $p->get_tag("tr")) {
        if ($token->[1]{style} and ($token->[1]{style} =~ /^height: 30px/)) {
          $token = $p->get_tag('strong');
          $evento = $p->get_trimmed_text('/strong');
          if ($evento =~ /MES SIN CONCIERTOS/) { next; }
          $token = $p->get_tag('span'); 
          $token = $p->get_token;  
          ($dia,$hora) = $token->[1] =~ /\w+&nbsp;(\d+)\s+-\s+(\d+:\d+)h/;
          $event{title} = $evento;
          $event{startDate} = $year . "-" . $mes . "-" . $dia . " " . $hora . ":00";
          
          $token = $p->get_tag('p'); # hay dos tables pero recien la descripcion empieza con un parrafo
          $token = $p->get_token; # font
          $token = $p->get_token;    
          if (($token->[1] =~ /img/)) {
            $event{image} = $weburl.$token->[2]{src};
          }
          # ahora viene el descripcion. en algunos casos tienen empty <p> por lo que voy a buscar el texto hasta el <a>
          $descripcion = $p->get_trimmed_text('a'); 

          $token = $p->get_tag('a');
          $event{bandadetailurl} = $token->[1]{href} || "-";
          $token = $p->get_tag('/font'); # avanzo para salir del a, en este caso, de la descripcion del tag
          my $texto = $p->get_trimmed_text('/td'); # busco texto hasta que termina la columna a ver si hay otro artista
          if ($texto =~ /http:\/\//) { # si hay una url hay otro artista
            $event{description} .= " " . $texto;
          }
          $token = $p->get_tag('/strong');
          $token = $p->get_token; # 
          $precio = $token->[1];
          $precio =~ /&nbsp;(.*)&#8364;.*/;
          $precio = $1;
          if ($precio =~ /\d/) { $event{price} = $precio; } else { $event{price} = NULL; }
          $token = $p->get_tag('span');
          $event{puntosventa} = $p->get_trimmed_text('/span');
          push @events, {%event};          
        }
      }      
    }
  } # end while table
    if (($nexturl) && $i < 3 ) { 
      get_events('nexturl', $nexturl);
    }  
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

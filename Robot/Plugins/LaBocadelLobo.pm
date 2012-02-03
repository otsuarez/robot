package LaBocadelLobo;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    

# titulo, description, starDate, price, image, bandadetailurl


use Encode;
use Data::Dumper;
binmode(STDOUT, ":utf8"); 

sub get_events {
    use HTML::TokeParser;
    use LWP::Simple;
    use HTML::Entities;
    
    my $sarasa = shift;
    my $url = shift;
    $url =~ m/(http:\/\/\w.*\/).*/g;
    my $siteurl = $1;
    
    my $data = LWP::Simple::get($url) or die $!;
    my $p = HTML::TokeParser->new(\$data);

    my $price ='';
    my $title = '';
    my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag, $bandaurl);
    my $yy; my $mm; my $dd; my $hh; my $mn;
    my $date; my $time;
    my %event = ();
    my @events = ();
    my $i = 0;
    my ($month, $year) = (localtime)[4,5];
    $month = $month+1;
    $month =~ s/^(\d)$/0$1/;
    $year = $year + 1900;
    while (my $token = $p->get_tag("table")) {
      if ($token->[1]{cellspacing} and ($token->[1]{cellspacing} =~ /^10/)) {    
        $token = $p->get_tag('div');
        $titulo = $p->get_trimmed_text('/div');
        $event{title} = $titulo;
        $token = $p->get_tag('div');
        $fecha = $p->get_trimmed_text('/div');
        $fecha =~ /(\w+)\s+(\d+)\s+(.*)/;
        $dd = $2;
        $inicio = $3;
        $hh = "22"; $mm = '00';
        if ($inicio =~ /\dh/) {
          if ($inicio =~ /\./) {
            $inicio =~ /(\d+)\.(\d+)\h/;
            $hh = $1; $mm = $2;
          } else {
            $inicio =~ /(\d+)\h/;
            $hh = $1; $mm = "00";            
          }
        } else {
          $inicio =~ /.*partir de las (\d+).*/;
          $hh = $1; $mm = "00";            
        }

        $event{startDate} = $year . "-" . $month . "-" . $dd . " " . $hh . ":" . $mm;
        $token = $p->get_tag('div');
        $precio = $p->get_trimmed_text('/div');
        if ($precio =~ /entrada libre/) {
          $precio = 'free';
        } 
        $event{price} = $precio;
        $token = $p->get_tag('table');        
        $token = $p->get_tag('tr');
        $token = $p->get_tag('tr');
        $token = $p->get_tag('td');
        if ($token->[1]{class} and ($token->[1]{class} =~ /^texto/)) { # no hay imagen...
          $img = NULL;
        } else { # si hay imagen
          $token = $p->get_tag('a');
          $siteurl =~ s/(http.*)laboca\//$1/;
          $img = $token->[1]{href};
          $img =~ s/\.\.\/(.*)/$1/;
          $img = $siteurl.$img;
          $token = $p->get_tag('td');
          $token = $p->get_tag('td'); # ya estamos en el texto
        }

        $description = '';
        $event{description} =  encode('utf8', $p->get_trimmed_text('/td'));
        $token = $p->get_tag('/table'); # salimos de ese table
        $token = $p->get_tag('/table'); # aca viene la imagen del segundo artista. se ignora.   
        $token = $p->get_tag('td'); 
        $bandaurl = NULL;        
        if ($token->[1]{class} and ($token->[1]{class} =~ /^texto_negrita/)) { # hay enlaces relacionados
          # tomo solo el primero
          $token = $p->get_tag('a');
          $bandaurl = $token->[1]{href};
          $bandaurl =~ s/frame.php\?url=(http.*)/$1/;
        }
        $event{bandadetailurl} = $bandaurl;
        push @events, {%event};
      }
    }
    return @events;
}

1;

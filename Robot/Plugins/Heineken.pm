package Heineken;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    




use Encode;
use Data::Dumper;

sub smartdecode {
  use URI::Escape qw( uri_unescape );
  use utf8;
  my $x = my $y = uri_unescape($_[0]);
  return $x if utf8::decode($x);
  return $y;
}


sub get_events {
    use HTML::TokeParser;
    use LWP::Simple;
    use HTML::Entities;
    BEGIN {
      *lwp_get  = \&LWP::Simple::get;
    }
    my $sarasa = shift;
    my $url = shift;
    $url =~ m/(http:\/\/\w.*\/).*/g;
    my $web = $1;
    
    my $data = LWP::Simple::get($url) or die $!;
    my $p = HTML::TokeParser->new(\$data);
    my $price ='';
    my $title = '';
    my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag);
    my $yy; my $mm; my $dd; my $hh; my $mn;
    my $date; my $time;
    my %event;
    my @events;
    my $i = 0;

    while (my $token = $p->get_tag("table")) {
      if ($token->[1]{id} and ($token->[1]{id} =~ /^portada/)) {    
        $tag = $p->get_tag('a'); $tag = $p->get_tag('a');
		    $url = $tag->[1]{href} || "--";
		    $tag = $p->get_tag('img');
		    $img = $tag->[1]{src} || "--";
        $tag = $p->get_tag('td'); $tag = $p->get_tag('table');
		    $tag = $p->get_tag('tr'); $tag = $p->get_tag('span');
		    $titulo = $p->get_trimmed_text("/span");
		    $tag = $p->get_tag('span');
		    # aqui hay dos, el telonero y el segundo acto, en la web no se diferencian....
		    $subtitulo = $p->get_trimmed_text("/span");
		    $tag = $p->get_tag('td');
		    $fecha = $p->get_trimmed_text("/td");
		    $tag = $p->get_tag('td');
		    $inicio = $p->get_trimmed_text("/td");		
		    $tag = $p->get_tag('td');
		    $precio = $p->get_trimmed_text("/td");		
		    $tag = $p->get_tag('td');
		    $tag = $p->get_tag('a');
        my $ventalink = $tag->[1]{href} || "--";
		    $puntosventa = encode_entities($p->get_trimmed_text("/td"));
		    $puntosventa  =~ s/&nbsp;//g;
		    
		    $event{title} = $titulo;
		    $event{subtitle} = $subtitulo;
		    # description
		    $event{image} = $web.$img;
		    $event{puntosventa} = $puntosventa;
		    $event{ventalink} = $ventalink;

        # 'startDate' => 'Jueves 03.12.09'
        # DATETIME	'0000-00-00 00:00:00'
		    $fecha =~ s/^\w.*\s+(\d.*)$/$1/;
		    ($dd,$mm,$yy) = split (/\./,$fecha);
		    $yy = "20".$yy;
		    $date = join "-",$yy,$mm,$dd;

		    # los minutos tienen varios formatos: 20:00h 20:00 h. 20:00h. 20h.
		    $inicio =~ s/^Apertura de puertas:\s+(\d+)(.*)h.*//;
		    $hh = $1; $mn = $2;		  
		    $mn =~ s/://;
		    $mn =~ s/\s+//; #  20:00 h.s
		    if ($mn eq "") { $mn = '00'; }  
		    $time = join ":",$hh,$mn,"00";

		    $fecha = $date." ".$time; 
		    $event{startDate} = $fecha;

        # 'price' => 'precio: 20 Euros (+gastos venta anticipada)',
		    $precio =~ s/^precio: //;
		    $event{price} = $precio;
        push @events, {%event};
        $i++;
      }
    }
    return @events;
}

1;

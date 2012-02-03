package RincondelArteNuevo;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    


use Encode;
use Data::Dumper;

sub get_events {
    use HTML::TokeParser;
    use LWP::Simple;

    my $sarasa = shift;
    my $url = shift;
    
    my $data = LWP::Simple::get($url) or die $!;
    my $p = HTML::TokeParser->new(\$data);

    my $price ='';
    my $title = '';
    my ($titulo, $subtitulo, $img, $link, $fecha, $inicio, $precio, $puntosventa, $tag);
    my $yy; my $mm; my $dd; my $hh; my $mn;
    my $date; my $time;
    my %event = ();
    my @events;
    my $i = 0;
    while (my $token = $p->get_tag("table")) {
      if ($token->[1]{width} and ($token->[1]{width} =~ /^615/)) {    
        $token = $p->get_tag('input');
        if (($token->[1]{value}) && ($token->[1]{name} =~ /calEvtLocation/)) {
          $event{title} = $token->[1]{value};
          $token = $p->get_tag('input');
          $token = $p->get_tag('input');
          $token = $p->get_tag('input');
          $token = $p->get_tag('input');
          $token = $p->get_tag('input');
          $token = $p->get_tag('input');
          if (($token->[1]{value}) && ($token->[1]{name} =~ /calEvtDateTime/)) {
            $fecha  = $token->[1]{value};
            $fecha =~ /(\d+-\d+)-(\d+) (\d+:\d+)/;
            $event{startDate} = $2 . "-" . $1 . " " . $3;
          } 
        }
        push @events, {%event};
        $i++;
      }
    }
    return @events;
}

1;

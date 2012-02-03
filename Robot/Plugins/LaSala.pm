package LaSala;
require      Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(get_events);    

my $fotourl = "http://www.lasala.biz/img/eventos/";

# la base de datos tiene dos campos: puntosventa y ventalink, en este caso
# se pueden tener mas de uno por evento. armo entonces un string separado por dos puntos que luego
# pueden haber hasta tres puntos de venta y/o los respectivos links
# verifico si hay punta de venta y lo guardo, si hay enlace lo guardo y si no, guardo "-" para respetar
# el lugar por si hay un segundo punto de venta que si tenga link
# utilizo como separador "|" en cada caso entre los tres valores

#	<evento fecha="17-06-2009" dia="Miércoles"> 
#			<foto>noches_directo.jpg</foto> 
#			<nombre_evento>Noches de Directo.Rock</nombre_evento> 
#			<grupos>VOZ MERCURIA + MUAKA + SYLFIDES </grupos> 
#			<apertura_puertas>21:00h</apertura_puertas>			
#			<precio_anticipado>6€ (con cerveza)</precio_anticipado> 
#			<lugaresDeVenta> 
#				<lugarDeVenta> 
#					<nombre></nombre> 
#					<link></link> 
#				</lugarDeVenta> 
#				<lugarDeVenta> 
#					<nombre></nombre> 
#					<link></link> 
#				</lugarDeVenta> 
#				<lugarDeVenta> 
#					<nombre></nombre> 
#					<link></link> 
#				</lugarDeVenta> 
#			</lugaresDeVenta> 
#			<precio_sala>8€</precio_sala> 
#			<descripcion>Una oportunidad para descubrir a tres bandas de la escena independiente madrileña a un precio razonable.</descripcion> 
#			<linkDescripcion></linkDescripcion> 
#	</evento> 


if ($debug) {
  use Data::Dumper;
}


sub get_events {
  use LWP::Simple;
  use XML::TokeParser;

  my $sarasa = shift;
  my $url = shift;
  my %event = (); # arranco con un H limpio
  my @events = ();
  my $dia; my $fecha; my $foto; my $evento; my $grupos; my $inicio; my $precio; 
  my $puntosventa; my $ventalink; my $descripcion; my $bandadetailurl; my $fotofile;
  # precio anticipado
  my $precio1;
  # precio
  my $precio2;

  my $data = LWP::Simple::get($url) or die $!;
  $data =~ s/\&/\&amp;/g;
  my $p = XML::TokeParser->new(\$data);
  my $token;
  while ($token = $p->get_tag("evento")) {
    $dia = $fecha = $foto = $evento = $grupos = $inicio = $precio = '';
    $puntosventa = $ventalink = $descripcion = $bandadetailurl = $precio1 = $precio2 = $fotofile =  '';
    %event = ();
    $dia = $token->[1]{dia};
    $fecha= $token->[1]{fecha};
    $token = $p->get_token; # foto
    $token = $p->get_token; # empty space or viceversa
    $token = $p->get_token; # la foto como tal
    $fotofile = $token->[1];
    if ($fotofile =~ /\w/) {
      $foto = $fotourl.$fotofile;   
    }
    $token = $p->get_token; # /foto
    $token = $p->get_token; # start nombre_evento
    $token = $p->get_token; #   
    $token = $p->get_token; #   
    $evento = $token->[1];
    $event{title} = $evento;
    $token = $p->get_tag('grupos'); # /foto
    $grupos = $p->get_trimmed_text('/grupos');
    if ($grupos =~ /\w/) {
      $event{subtitle} = $grupos;
    }
    $token = $p->get_tag('apertura_puertas');
    $inicio = $p->get_trimmed_text('/apertura_puertas');
    $fecha =~ /(\d+)-(\d+)-(\d+)/;
    $fecha = $3 . "-" . $2 . "-" .$1 . " ";
    $inicio =~ /(\d\d:\d\d).*/;
    $inicio = $1 . ":00"; 
    $fecha = $fecha.$inicio;
    $event{startDate} = $fecha;
    $token = $p->get_tag('precio_anticipado');
    $precio1 = $p->get_trimmed_text('/precio_anticipado');
    if ($precio1 =~ /\w/) {
      $precio1 = "Precio anticipado: ".$precio1.".";
      $event{price} = $precio1;
    } else {
      #   "no tengo precio \n";
    }

    $token = $p->get_tag('lugaresDeVenta');
    $puntosventa = $ventalink = '';
    $token = $p->get_tag("lugarDeVenta");
    $token = $p->get_tag('nombre');
    $puntosventa = $p->get_trimmed_text('/nombre');
    if ($puntosventa =~ /\w/) {
      $token = $p->get_tag('link');
      $ventalink = $p->get_trimmed_text('/link');
      $event{puntosventa} = $puntosventa;
      if ($ventalink =~ /\w/) {
        $event{ventalink} = $ventalink;
      } else {
        $event{ventalink} = "-";
      }
      $token = $p->get_tag("lugarDeVenta");
      $token = $p->get_tag('nombre');
      $puntosventa = $p->get_trimmed_text('/nombre');
      if ($puntosventa =~ /\w/) {
        $token = $p->get_tag('link');
        $ventalink = $p->get_trimmed_text('/link');
        if ($ventalink =~ /\w/) {
          $event{ventalink} = $ventalink;
        } else {
          $event{ventalink} = "-";
        }
        $event{puntosventa} = $event{puntosventa} . " | " . $puntosventa;
        $event{ventalink} = $event{ventalink} . " | " . $ventalink;      
        $token = $p->get_tag("lugarDeVenta");
        $token = $p->get_tag('nombre');
        $puntosventa = $p->get_trimmed_text('/nombre');
        if ($puntosventa =~ /\w/) {
          $token = $p->get_tag('link');
          $ventalink = $p->get_trimmed_text('/link');
          if ($ventalink =~ /\w/) {
            $event{ventalink} = $ventalink;
          } else {
            $event{ventalink} = "-";
          }
          $event{puntosventa} = $event{puntosventa} . " | " . $puntosventa;
          $event{ventalink} = $event{ventalink} . " | " . $ventalink;      
        }
      }
    }    
    $token = $p->get_tag('precio_sala');
    $precio2 = $p->get_trimmed_text('/precio_sala');
    if ($precio2 =~ /\w/) {  
      $event{price} = $precio1 . " Precio: " . $precio2 . "."; 
    }
    $token = $p->get_tag('descripcion');
    $descripcion = $p->get_trimmed_text('/descripcion');
    if ($descripcion =~ /\w/)  {
      $event{description} = $descripcion;
    }
    $token = $p->get_tag('linkDescripcion');
    $bandadetailurl = $p->get_trimmed_text('/linkDescripcion');
    if ($bandadetailurl =~ /\w/) {
      $event{bandadetailurl} = $bandadetailurl;
    }
  push @events, {%event};
  } # end while evento
  return @events;
}

1;

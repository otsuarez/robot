## Robot

[[InstalandoPerlModules]]

## Files ##


engine.pl
sites/
sites/heineken.config
Robot/
Robot/Config.pm
Robot/Plugins
Robot/Plugins/Heineken.pm


engine.pl
Es el script que se invoca. Carga la configuracion la base de datos y paths de Robot/Config.pm. Carga todos los archivos que esten en el directorio sites/ y los procesa

sites/
En esta carpeta se crea un archivo por cada sitio.
Cada linea esta compuesta de la forma key=value (se ignoran comentarios - lineas que comienzan con # - y en blanco)

Robot/
En esta carpeta se guardan las librerias del proyecto.

Robot/Config.pm
Aqui se guarda toda la configuracion del engine.pl. Evita tener que editar el script principal.

Robot/Plugins
En esta carpeta se almacen los Plugins. Un plugin es un package que incluye el codigo necesario para a partir de una url, devolver los datos parseados de dicha pagina.

sites/
En esta carpeta se almacenan los archivos que definen los sitios a parsear. Estos archivos se utilizan en formato .ini. Las opciones disponibles se detallan  [OpcionesArchivosSites  aquí].

El script engine.pl carga los archivos sites/*.config. De esos archivos toma la url del sitio, y el nombre del plugin. Le pasa la url al plugin y recibe los datos parseados. Los cuales los escribe en la base de datos. Antes de escribir el dato, chequea si no existia ya.


(nota: los archivos de configuración deben ser renombrados a *.ini para reflejar mejor el formato que utilizan)

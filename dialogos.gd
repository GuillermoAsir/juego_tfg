extends Node


# --- MISIÓN INICIAL ---
var mision_inicial_dialogs1 = [
	"Excelente, ya te encuentras en el directorio donde está el archivo.\n" +
	"Ahora falta listarlo para asegurarnos que se encuentra ahí.\n" +
	"Para ello usaremos el comando `ls`. Solo tienes que escribir `ls` y pulsar la tecla intro."
]

var mision_inicial_dialogs2 = [
	"¡Perfecto! Has encontrado el archivo `IPS_Departamentos.txt`.\n" +
	"Ahora falta un paso más: ver el contenido de dicho fichero.\n" +
	"Para ello vas a usar el comando `cat` seguido del nombre del fichero,\n" +
	"por ejemplo: `cat IPS_El_Bohío.txt`. ¡Vamos, usa a ese gatito!"
]

var mision_inicial_dialogs3 = [
	"Puedes ver que la IP del departamento de ventas es 192.168.10.10 y su puerta de enlace es 192.168.10.1.\n" +
	"Su puerta de enlace es el router desde donde le llega la conexión a internet.\n" +
	"Usa el comando `ping 192.168.10.10` del ordenador del departamento de ventas para ver si funciona.\n" +
	"Recuerda si quieres que el comando se detenga pulsa las teclas Ctrl + C"
]

var mision_inicial_dialogs4 = [
	"El ping ha sido un éxito eso quiere decir que el problema no está con su equipo,\n" +
	"prueba hacer ping a la puerta de enlace."
]

var mision_inicial_dialogs5 = [
	"Inténtalo con el ping 192.168.10.1"
]
var mision_inicial_dialogs6 = [
	"¡Por todos los nodos! Al router le pasa algo,\n" +
	"Ahora mismo les mando un mensaje para que utilicen la técnica ancestral de todo buen informático...\n" +
	"Reiniciar el router"
]

var mision_inicial_dialogs7 = [
	"Enhorabuena por este gran éxito, ¡aquí te dejo tu pin!",
	"Pam:\n\nSaludos soy Pam me han llegado muchos email donde dicen nuestros clientes que nuestra web no funciona.",
	"Viejo:\n\nOMG! Repampanos y retuecanos ¡¿es que nadie hará nada?! Ah bueno nosotros.\n" +
	"Informáticos al rescate. Nuestra Web esta desde el servicio apache el indio apache noo!\n" +
	"Apache es el servicio web. Hoy vas a mirar el estado del servicio y si esta mal lo vas a resetear.\n" +
	"Empecemos mirando el estado solo tienes que escribir `sudo systemctl status apache`."
]



# --- MISION APACHE ---
var apache_dialogs1 = [
	"Vaya tenemos un error en rojo los peores de todos! Vamos a resetear el servicio Apache ahora escribe `sudo systemctl restart apache`."
]
var apache_dialogs2 = [
	"Ahora puede volver a mirar el estado del servicio."
]
var apache_dialogs3 = [
	"Viejo: Muy bien!! Luego me acercare hablar con Pam para decirle que lo hemos solucionado. Misión terminada consultar apache. \n",
	"Departamento de Contabilidad: Hola soy Miguel, quería pediros si podríais realizar una copia a la carpeta llamada\n"+
	"Privado esta situado en Documentos, es importante para mi y no seáis unos cotillas nada!",
	"Viejo: Ya sabes que tienes que hacer, ingresa al equipo desde el servicio ssh del empleado de contabilidad  \n"+
	"solo tienes que ir a la terminal y escribir ssh contabilidad@192.168.10.100. Recuerda donde están guardas las Ips."
]

# --- MISION SSH ---
#El jugador se conecta por ssh a contabilidad@192.16.10.100 salta este dialogo:
var ssh_cp_dialogs1 =[
	"Viejo: Muy bien ya estás dentro! busca el fichero y realiza la copia\n"+
	"Usa el comando cp cuando estes situado dentro de la carpeta Documentos y escribe cp Privado Privado.old"
]
#El jugador tiene que usar ls si no le salta el dialogo ssh_cp_dialogs3: 
var ssh_cp_dialogs2 = [
	"Viejo: Marcial, no te olvides de listar para asegurarte de que se realizó bien la copia."
]
#Si el jugador ha realizado el comando ls en la ruta contabilidad\Documentos y a hecho cp en el directorio carpeta:
var ssh_cp_dialogs3 = [
	"Viejo: Muy bien, ahora sal del ordenador del empleado con 'exit'."
]
#Si el jugador  déspùes de empezar el apache_dialogs5 usa el cat en el fichero Para_Pam le salta este dialogo:
var ssh_cp_dialogs4 =[
	"Viejo: Pero serás cotilla!!...\n "+
	"Cuenta cuenta..."
]
var ssh_cp_dialogs5 = [
	"Departamento de Contabilidad: Hola, le hablamos desde el departamento de contabilidad.\n" +
	"No podemos guardar nada más en el ordenador. Un saludo",
	"Me da mucha pereza ir para ya, vas a conectarte con el servicio ssh al equipo, \n" + 
	"es muy sencillo solo tienes que ir a la terminal y escribir ssh contabilidad@	<Ip Contabilidad>. \n" +
	"Recuerda donde están guardas las Ips."
] 


# --- MISION SSH LIMPIAR ---
var ssh_clean_dialogs1 = [
	"Viejo: Ahora ya estás dentro. Creo que debe ser un problema de almacenamiento. Para ver el uso del disco, utiliza el comando:\ndf -h /contabilidad\nEn la columna 'Use%' podrás ver el porcentaje utilizado."
]

var ssh_clean_dialogs2 = [
	"Viejo: ¡Un 98%! Madre mía, ¿quién ha descuidado tanto ese ordenador? Mmm... vaya, creo que ese soy yo. Je je. Pero no te preocupes, hay solución.\nEscribe: sudo apt-get clean\nContraseña: 1234",
	"Este comando eliminará los paquetes descargados que ya no son necesarios,\n"+
	"liberando espacio en el disco. ¡Es como barrer debajo de la alfombra digital!\n"+
	"Pero cuidado, no borra programas instalados, solo limpia archivos temporales."
]

var ssh_clean_dialogs3 = [
	"Viejo: Buen trabajo. Ahora sigue con: sudo apt-get autoclean",
	"Este comando elimina paquetes antiguos que ya no sirven de nada."
]

var ssh_clean_dialogs4 = [
	"Viejo: Bien hecho. Siguiente paso: sudo apt-get autoremove",
	"¡Vamos bien! Este comando va a deshacerse de los paquetes que ya no hacen falta\n" +
	"cada vez su disco dejará de parece un Grimer y más aún Jigglypuff"
]

var ssh_clean_dialogs5 = [
	"Viejo: Excelente. Ahora dejamos esto limpio como recién estrenado. Ejecuta:\nrm -r /tmp/*",
	"Ahora sí, esto va a quedar tan limpio como si Shenron hubiera concedido un deseo de restauración total\n"+
	"Este comando borra todos los archivos temporales"
]

var ssh_clean_dialogs6 = [
	"Viejo: Perfecto. Ahora ejecuta:\n rm -r /var/tmp/*",
	"Este comando elimina archivos temporales de /var/tmp/, asegurando que el sistema esté limpio\n"+
	"Esto es como usar la definitiva de Janna:\n"+
	"todo el desorden se esparce, los problemas desaparecen, y el sistema vuelve a respirar tranquilamente"
]

var ssh_clean_dialogs7 = [
	"Viejo: ¡Muy bien! Ahora borramos las descargas del usuario con:\nrm -rf /contabilidad/Descargas/*"
]

var ssh_clean_dialogs8 = [
	"Viejo: ¡Perfecto! Ahora limpiamos la papelera, empecemos con:\nrm -r /contabilidad/.local/share/Trash/files/*"
]

var ssh_clean_dialogs12 = [
	"Viejo: Y ahora contabilidad/.local/share/Trash/info/*"
]

var ssh_clean_dialogs9 = [
	"Viejo: ¡Perfecto! Verifica el uso del disco nuevamente con:\ndf -h"
]

var ssh_clean_dialogs10 = [
	"Viejo: ¡Un 70%! Eso ya es otra cosa. Ya podrán volver a descargarse películas... jeje, guiño guiño.\nAhora puedes salir del servidor con:\nexit"
]

var ssh_clean_dialogs11 = [
	"Viejo: Ya hemos terminado esta increíble aventura. ¡Ni WALL-E limpiaba tan bien!"
]

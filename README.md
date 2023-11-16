# Deploy Django Helper

El objetivo de este script es guiar al usuario en la configuracion de produccion de un proyecto con django.

**\*Nota\*\***
Este script fue creado para ubuntu y fue probado en ubuntu 18.04 20.04 y 22.04

## Requisitos

- vps o servidor con ubuntu server instalado
- acceso root via ssh al servidor
- un dominio que apunte a la ip del servidor

## Caracteristicas

1. Verifica e instala de ser necesario todos los paquetes para poner a funcionar un proyecto django en ubuntu `("python3" "python3-pip" "python3-venv" "libpq-dev" "python3-dev" "build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" "libncurses5-dev" "libncursesw5-dev" "xz-utils" "tk-dev" "libffi-dev" "git")`
2. Configurara e instalara el motor de base de datos que se requiera `(mysql, postgresql)` y configura usuario root con contraseña segura aleatoria
3. Opcion para crear una base de datos, usuario y password para el proyecto.
4. Crea el sistema de archivos y entonrno virtual para el proyecto
5. Permite instalar mas de un proyecto y da la posibilidad de cambiar el puerto donde se ejecute cada proyecto, puertos disponibles (8001 - 8999) excluyendo el puerto 8080 y y como puerto predeterminado 8000
6. Permite instalar los paquetes requeridos para el proyecto 'requirements.txt'
7. Permite clonar el proyecto desde repositorio
8. Permite agregar el dominio y configura nginx
9. Instala certbot y permite configurar los certificados ssl para el dominio del proyecto
10. Configura supervisor para poner el proyecto en marcha

## Uso

1. Clonar el repositorio del proyecto
   `git clone https://github.com/HerrWolf/DeployDjangoHelper`

2. Ingresar al directorio del script
   `cd DeployDjangoHelper`

3. Dar permisos de ejecucion
   `chmod +x script_deploy_django_app.sh utils.ssh`

4. Ejecutar script
   `./script_deploy_django_app.sh`

5. Seguir los pasos del script

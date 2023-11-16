#!/bin/bash

source ./utils.sh

# Actualizar la lista de paquetes e instalar actualizaciones
sudo apt update
sudo apt upgrade -y

# Paquetes necesarios para Django (excluyendo motores de bases de datos)
django_packages=("python3" "python3-pip" "python3-venv" "libpq-dev" "python3-dev" "build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" "libncurses5-dev" "libncursesw5-dev" "xz-utils" "tk-dev" "libffi-dev" "git")

# Verificar e instalar paquetes necesarios para Django con manejo de errores
for package in "${django_packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "installed"; then
        handle_package_installation "$package"
    else
        echo "$package ya está instalado."
    fi
done

# Elección del motor de base de datos
echo "┌──────────────────────────────────────────────────────────────────┐"
echo "│  ¿Qué base de datos le gustaría usar para su aplicación Django?  │"
echo "│  1. MariaDB (MySQL)                                              │"
echo "│  2. PostgreSQL                                                   │"
echo "└──────────────────────────────────────────────────────────────────┘"
read -p "Seleccione una opción (1 o 2): " db_choice

case $db_choice in
    1)
        db_engine="mysql"
        configure_mysql_user
        ;;
    2)
        db_engine="postgres"
        configure_postgres_user
        ;;
    *)
        echo "┌──────────────────────────────────────────┐"
        echo "│  Opción no válida. Saliendo.             │"
        echo "└──────────────────────────────────────────┘"
        exit 1
        ;;
esac

# Lógica para crear un usuario y una base de datos adicionales
read -p "¿Desea crear un usuario y una base de datos para el proyecto? (si/no): " create_db_option

case $create_db_option in
    si)
        read -p "Ingrese el nombre de la base de datos para el proyecto: " db_name
        project_name_user="${db_name}_user"
        create_database_user "$db_name"
        echo "Presione Enter para continuar..."
        read
        ;;
    no)
        echo "Continuando con el script."
        ;;
    *)
        echo "Opción no válida. Por favor, responda con 'si' o 'no'."
        # Lógica para volver a preguntar si quiere crear un usuario y base de datos
        ;;
esac

# Instalación de paquetes según la elección del usuario
if [ "$db_engine" = "mysql" ]; then
    sudo apt install -y mysql-server libmysqlclient-dev
    if [ $? -ne 0 ]; then
        echo "Error al instalar MySQL. Por favor, verifique."
    fi
elif [ "$db_engine" = "postgres" ]; then
    sudo apt install -y postgresql postgresql-contrib libpq-dev
    if [ $? -ne 0 ]; then
        echo "Error al instalar PostgreSQL. Por favor, verifique."
    fi
fi

# Verificar e instalar Git si no está presente
if ! command -v git &>/dev/null; then
    echo "┌──────────────────────────────────────────┐"
    echo "│  Git no está instalado. Instalando...    │"
    echo "└──────────────────────────────────────────┘"
    sudo apt install -y git
    if [ $? -ne 0 ]; then
        read -p "Hubo un error al instalar Git. ¿Desea intentar nuevamente? (si/no): " try_again
        case $try_again in
            si)
                sudo apt install -y git
                ;;
            no)
                echo "No se instalará Git. Saliendo del script."
                exit 1
                ;;
            *)
                echo "┌────────────────────────────────────────┐"
                echo "│  Por favor, responda con 'si' o 'no'.  │"
                echo "└────────────────────────────────────────┘"
                ;;
        esac
    else
        echo "┌──────────────────────────┐"
        echo "│  Git ya está instalado.  │"
        echo "└──────────────────────────┘"
    fi
else
    echo "┌─────────────────────────┐"
    echo "│  Git ya está instalado. │"
    echo "└─────────────────────────┘"
fi

# Solicitar el nombre del proyecto al usuario
read -p "Ingrese el nombre del proyecto: " project_name

# Verificar si el directorio /webapps existe
webapps_dir="/webapps"

if [ ! -d "$webapps_dir" ]; then
    echo "┌──────────────────────────────────────────────────────┐"
    echo "│  El directorio $webapps_dir no existe. Creándolo...  │"
    echo "└──────────────────────────────────────────────────────┘"
    sudo mkdir -p "$webapps_dir"
    sudo chown $USER:$USER "$webapps_dir"
    echo "Directorio $webapps_dir creado."
else
    echo "┌─────────────────────────────────────────┐"
    echo "│  El directorio $webapps_dir ya existe.  │"
    echo "└─────────────────────────────────────────┘"
fi

project_dir="$webapps_dir/$project_name"

# Crear directorio del proyecto y entorno virtual
sudo apt install -y python3-venv

if [ ! -d "$project_dir" ]; then
    echo "┌─────────────────────────────────────────────────┐"
    echo "│  Creando directorio del proyecto: $project_dir  │"
    echo "└─────────────────────────────────────────────────┘"
    sudo mkdir "$project_dir"
    sudo chown $USER:$USER "$project_dir"

    echo "┌──────────────────────────────────────────┐"
    echo "│  Creando entorno virtual...              │"
    echo "└──────────────────────────────────────────┘"
    python3 -m venv "$project_dir"
    if [ $? -ne 0 ]; then
        echo "Error al crear el entorno virtual. Verifica y vuelve a intentarlo."
        delete_project_directory
    fi
else
    echo "┌──────────────────────────────────────────────────────┐"
    echo "│  El directorio del proyecto $project_dir ya existe.  │"
    echo "└──────────────────────────────────────────────────────┘"
fi

# Crear carpeta "app" dentro del directorio del proyecto
if [ -d "$project_dir" ]; then
    app_dir="$project_dir/app"
    if [ ! -d "$app_dir" ]; then
        echo "┌──────────────────────────────────────────────────────────┐"
        echo "│  Creando carpeta 'app' en el directorio del proyecto...  │"
        echo "└──────────────────────────────────────────────────────────┘"
        sudo mkdir "$app_dir"
        sudo chown $USER:$USER "$app_dir"
        echo "Carpeta 'app' creada en $project_dir."
    else
        echo "┌───────────────────────────────────────────────┐"
        echo "│  La carpeta 'app' ya existe en $project_dir.  │"
        echo "└───────────────────────────────────────────────┘"
    fi
else
    echo "┌──────────────────────────────────────────────────────┐"
    echo "│  El directorio del proyecto $project_dir no existe.  │"
    echo "└──────────────────────────────────────────────────────┘"
fi

# Mensaje sobre credenciales SSH
echo "┌─────────────────────────────────────────────────────────┐"
echo "│  Nota: Para clonar un repositorio privado               │"
echo "│  Asegúrate de tener configuradas las credenciales SSH.  │"
echo "│  O generar un token de autenticacion en Github          │"
echo "└─────────────────────────────────────────────────────────┘"

# Pedir al usuario la URL del repositorio a clonar
read -p "Ingrese la URL del repositorio a clonar: " repo_url

# Clonar el repositorio en el directorio "app"
if [ -d "$app_dir" ]; then
    echo "Clonando el repositorio en $app_dir..."
    git clone "$repo_url" "$app_dir"

    # Activar el entorno virtual
    source "$project_dir/bin/activate"

    if [ -n "$VIRTUAL_ENV" ]; then
        echo "┌────────────────────────────────────────────────────┐"
        echo "│  El entorno virtual se ha activado correctamente.  │"
        echo "└────────────────────────────────────────────────────┘"
        sleep 2
    else
        echo "┌────────────────────────────────────────────────────────────────────────┐"
        echo "│  Error al activar el entorno virtual. Verifica la ruta proporcionada.  │"
        echo "└────────────────────────────────────────────────────────────────────────┘"
        exit 1  # Salir del script con un código de error (en este caso, 1
    fi

    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│  En este momento el proyecto ya esta clonado dentro de la carpeta app   │"
    echo "│  puede ingresar via ssh a la ruta del proyecto y configurar el archivo  │"
    echo "│  settings.py y agregar su archivo .env si lo necesita.                  │"
    echo "│  Es aconsejable hacerlo antes de la instalacion de dependencias.        │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"

    # Preguntar al usuario si quiere instalar requirements (con manejo de entrada no válida)
    valid_input_requirements=false
    while [ "$valid_input_requirements" != true ]; do
        read -p "¿Desea instalar las dependencias del proyecto? (si/no): " install_requirements
        case "$install_requirements" in
            si)
                valid_input_requirements=true
                read -p "Ingrese la ruta del archivo requirements: " requirements_path
                
                if [ -f "$requirements_path" ]; then
                    valid_input_requirements=true
                    echo "Instalando dependencias desde $requirements_path..."
                    pip install -r "$requirements_path"
                    pip install pillow unipath gunicorn

                    echo "┌───────────────────────────────────────────────────┐"
                    echo "│  Las dependencias se han instalado correctamente  │"
                    echo "└───────────────────────────────────────────────────┘"
                else
                    valid_input_requirements=false
                    echo "El archivo requirements no existe en la ruta especificada."
                fi
                ;;
            no)
                echo "No se instalarán dependencias."
                ;;
            *)
                echo "Por favor, responda con 'si' o 'no'."
                ;;
        esac
    done

    # Desactivar el entorno virtual
    deactivate
else
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  El directorio 'app' en el proyecto $project_dir no existe.  │"
    echo "└──────────────────────────────────────────────────────────────┘"
fi

read -p "¿Desea introducir manualmente el puerto o utilizar el puerto predeterminado 8000? (manual/predeterminado): " port_option

case $port_option in
    manual)
        while true; do
            read -p "Por favor, introduzca un puerto del rango 8000 al 8999 (excluyendo 8080): " chosen_port
            if [[ $chosen_port -ge 8000 && $chosen_port -le 8999 && $chosen_port -ne 8080 ]]; then
                if ! lsof -i:$chosen_port; then
                    break
                else
                    echo "El puerto $chosen_port ya está en uso. Por favor, elija otro."
                fi
            else
                echo "Puerto no válido. Inténtalo de nuevo."
            fi
        done
        ;;
    predeterminado)
        chosen_port=8000
        if lsof -i:$chosen_port; then
            echo "El puerto $chosen_port está en uso. Por favor, elige otro."
            exit 1
        fi
        ;;
    *)
        echo "Opción no válida. Saliendo."
        exit 1
        ;;
esac

echo "┌───────────────────────────────────┐"
echo "│  Creando archivo gunicorn_start.  │"
echo "└───────────────────────────────────┘"

# Añadir al script main.sh
gunicorn_script="#!/bin/bash

NAME=\"${project_name}_app\"
DJANGODIR=/webapps/$project_name/app
SOCKFILE=/webapps/$project_name/run/gunicorn.sock
USER=root
GROUP=root
NUM_WORKERS=3
DJANGO_SETTINGS_MODULE=config.settings
DJANGO_WSGI_MODULE=config.wsgi

echo \"Starting \$NAME as \`whoami\`\"

# Activate the virtual environment
cd \$DJANGODIR
source ../bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

# Create the run directory if it doesn't exist
RUNDIR=\$(dirname \$SOCKFILE)
test -d \$RUNDIR || mkdir -p \$RUNDIR

# Start your Django Unicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec ../bin/gunicorn \${DJANGO_WSGI_MODULE}:application \\
  --name \$NAME \\
  --workers \$NUM_WORKERS \\
  --user=\$USER --group=\$GROUP \\
  --bind=unix:\$SOCKFILE \\
  --bind=0.0.0.0:$chosen_port \\
  --log-level=debug \\
  --log-file=-
"

# Escribir al archivo gunicorn_start
echo "$gunicorn_script" | sudo tee $project_dir/bin/gunicorn_start >/dev/null

# Dar permisos de ejecución al archivo gunicorn_start
sudo chmod u+x $project_dir/bin/gunicorn_start

# Ejecutar el archivo gunicorn_start
sudo $project_dir/bin/gunicorn_start

# Verificación del proyecto
verify_project_start

if [ $? -eq 0 ]; then
    echo "┌────────────────────────────────────┐"
    echo "│  El proyecto se inició con éxito.  │"
    echo "└────────────────────────────────────┘"
else
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│  No se pudo iniciar el proyecto. Verifica manualmente.  │"
    echo "└─────────────────────────────────────────────────────────┘"
    # Pedir al usuario que verifique el archivo gunicorn_start
    read -p "¿Has verificado el archivo gunicorn_start? ¿Quieres volver a intentar la verificación? (si/no): " verification_option

    case $verification_option in
        si)
            # Volver a realizar la verificación
            verify_project_start
            ;;
        no)
            echo "┌────────────────────────────────┐"
            echo "│  Continuando con el script...  │"
            echo "└────────────────────────────────┘"
            # Continuar con el resto del script
            ;;
        *)
            echo "┌─────────────────────────────────────────────────────┐"
            echo "│  Respuesta no válida. Continuando con el script...  │"
            echo "└─────────────────────────────────────────────────────┘"
            # Continuar con el resto del script
            ;;
    esac
fi

# Verificar e instalar Supervisor
if ! command -v supervisorctl &>/dev/null; then
    echo "Supervisor no está instalado. Instalando..."
    sudo apt-get install -y supervisor

    if [ $? -ne 0 ]; then
        echo "┌─────────────────────────────────────────────────────────────────────┐"
        echo "│  Error al instalar Supervisor. ¿Desea intentar nuevamente? (si/no)  │"
        echo "└─────────────────────────────────────────────────────────────────────┘"
        read try_again
        case $try_again in
            si)
                sudo apt-get install -y supervisor
                ;;
            no)
                echo "┌────────────────────────────────────────────────────┐"
                echo "│  No se instalará Supervisor. Saliendo del script.  │"
                echo "└────────────────────────────────────────────────────┘"
                exit 1
                ;;
            *)
                echo "┌────────────────────────────────────────┐"
                echo "│  Por favor, responda con 'si' o 'no'.  │"
                echo "└────────────────────────────────────────┘"
                ;;
        esac
    else
        echo "┌───────────────────────────────────────────────┐"
        echo "│  Supervisor ha sido instalado correctamente.  │"
        echo "└───────────────────────────────────────────────┘"
    fi
else
    echo "┌─────────────────────────────────┐"
    echo "│  Supervisor ya está instalado.  │"
    echo "└─────────────────────────────────┘"
fi

# Crear archivo de configuración de supervisor
# Crear archivo de configuración Supervisor
supervisor_conf="/etc/supervisor/conf.d/$project_name.conf"

if [ ! -f "$supervisor_conf" ]; then
    echo "┌─────────────────────────────────────────────────────┐"
    echo "│  Creando archivo de configuración para Supervisor:  │"
    echo "└─────────────────────────────────────────────────────┘"
    sudo tee "$supervisor_conf" > /dev/null <<EOF
[program:${project_name}_app]
command = /webapps/$project_name/bin/gunicorn_start
user = root
stdout_logfile = /webapps/$project_name/logs/gunicorn_supervisor.log
redirect_stderr = true
environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8
EOF

    if [ $? -ne 0 ]; then
        echo "┌───────────────────────────────────────────────────────────────┐"
        echo "│  Error al crear el archivo de configuración para Supervisor.  │"
        echo "└───────────────────────────────────────────────────────────────┘"
        exit 1
    else
        echo "┌──────────────────────────────────────────────────────────────────┐"
        echo "│  Archivo de configuración para Supervisor creado correctamente.  │"
        echo "└──────────────────────────────────────────────────────────────────┘"
    fi
else
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  El archivo de configuración para Supervisor ya existe.  │"
    echo "└──────────────────────────────────────────────────────────┘"
fi

# Crear directorio 'logs' y archivo 'gunicorn_supervisor.log'
logs_dir="$project_dir/logs"
gunicorn_log="$logs_dir/gunicorn_supervisor.log"

if [ ! -d "$logs_dir" ]; then
    echo "┌────────────────────────────────────────────────┐"
    echo "│  Creando directorio 'logs' en $project_dir...  │"
    echo "└────────────────────────────────────────────────┘"
    sudo mkdir -p "$logs_dir"
    if [ $? -ne 0 ]; then
        echo "┌─────────────────────────────────────────┐"
        echo "│  Error al crear el directorio 'logs'..  │"
        echo "└─────────────────────────────────────────┘"
        exit 1
    fi
else
    echo "┌───────────────────────────────────────────────────┐"
    echo "│  El directorio 'logs' ya existe en $project_dir.  │"
    echo "└───────────────────────────────────────────────────┘"
fi

if [ ! -f "$gunicorn_log" ]; then
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Creando archivo 'gunicorn_supervisor.log' en $logs_dir...  │"
    echo "└─────────────────────────────────────────────────────────────┘"
    sudo touch "$gunicorn_log"
    if [ $? -ne 0 ]; then
        echo "┌────────────────────────────────────────────────────────┐"
        echo "│  Error al crear el archivo 'gunicorn_supervisor.log'.  │"
        echo "└────────────────────────────────────────────────────────┘"
        exit 1
    fi
else
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│  El archivo 'gunicorn_supervisor.log' ya existe en $logs_dir.  │"
    echo "└────────────────────────────────────────────────────────────────┘"
fi

# Recargar configuración de Supervisor
sudo supervisorctl reread
sudo supervisorctl update
if [ $? -ne 0 ]; then
    echo "┌─────────────────────────────────────────────────────┐"
    echo "│  Error al recargar la configuración de Supervisor.  │"
    echo "└─────────────────────────────────────────────────────┘"
    echo ""
    exit 1
else
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│  Configuración de Supervisor recargada correctamente.  │"
    echo "└────────────────────────────────────────────────────────┘"
    echo ""
fi

# Preguntar al usuario el dominio a usar
read -p "Ingrese el dominio que se usará para la aplicación: " domain_name

# Verificar si Nginx está instalado
if ! command -v nginx &>/dev/null; then
    echo "┌──────────────────────────────────────────┐"
    echo "│  Nginx no está instalado. Instalando...  │"
    echo "└──────────────────────────────────────────┘"
    sudo apt-get update
    sudo apt-get install -y nginx

    if [ $? -ne 0 ]; then
        echo "┌──────────────────────────────────────────────────────────┐"
        echo "│  Hubo un error al instalar Nginx. Por favor, verifique.  │"
        echo "└──────────────────────────────────────────────────────────┘"
    else
        echo "┌────────────────────────────────────────┐"
        echo "│  Nginx se ha instalado correctamente.  │"
        echo "└────────────────────────────────────────┘"
    fi
else
    echo "┌────────────────────────────┐"
    echo "│  Nginx ya está instalado.  │"
    echo "└────────────────────────────┘"
fi

# Crear archivo de configuración Nginx
nginx_config="/etc/nginx/sites-available/$domain_name"

if [ ! -f "$nginx_config" ]; then
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  Creando archivo de configuración Nginx en $nginx_config...  │"
    echo "└──────────────────────────────────────────────────────────────┘"

    sudo tee "$nginx_config" > /dev/null <<EOF
upstream ${project_name}_app_server {
  server unix:/webapps/$project_name/run/gunicorn.sock fail_timeout=0;
}
 
server {
    server_name $domain_name;
 
    access_log /webapps/$project_name/logs/nginx-access.log;
    error_log /webapps/$project_name/logs/nginx-error.log;
 
    location /static/ {
        alias   /webapps/$project_name/app/staticfiles/;
    }
    
    location /media/ {
        alias   /webapps/$project_name/app/media/;
    }
 
    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_redirect off;

        if (!-f \$request_filename) {
            proxy_pass http://${project_name}_app_server;
            break;
        }
    }
}
EOF
    # Crear enlace simbólico a sites-enabled
    sudo ln -s $nginx_config /etc/nginx/sites-enabled/

    # Verificar la configuración de Nginx
    sudo nginx -t

    # Recargar la configuración de Nginx
    sudo systemctl reload nginx
else
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│  El archivo de configuración Nginx ya existe en $nginx_config.  │"
    echo "└─────────────────────────────────────────────────────────────────┘"
fi

# Preguntar al usuario si desea activar los certificados SSL
read -p "¿Desea activar los certificados SSL para el dominio ingresado? (si/no): " ssl_option

case $ssl_option in
  si)
    # Verificar e instalar Certbot
    if ! command -v certbot &>/dev/null; then
        echo "┌────────────────────────────────────────────┐"
        echo "│  Certbot no está instalado. Instalando...  │"
        echo "└────────────────────────────────────────────┘"
        sudo apt-get update
        sudo apt-get install certbot python3-certbot-nginx

        if [ $? -ne 0 ]; then
            echo "┌───────────────────────────────────────────────────┐"
            echo "│  Error al instalar Certbot. Saliendo del script.  │"
            echo "└───────────────────────────────────────────────────┘"
            exit 1
        fi
    else
        echo "┌──────────────────────────────┐"
        echo "│  Certbot ya está instalado.  │"
        echo "└──────────────────────────────┘"
    fi

    # Solicitar y configurar certificado SSL para el dominio
    sudo certbot --nginx -d $domain_name

    # Verificar si se han instalado correctamente los certificados
    if [ $? -eq 0 ]; then
        echo "┌───────────────────────────────────────────────────────────────────────────┐"
        echo "│  Certificados SSL instalados correctamente para el dominio $domain_name.  │"
        echo "└───────────────────────────────────────────────────────────────────────────┘"
    else
        echo "┌─────────────────────────────────────────────────────────────────┐"
        echo "│  Error al instalar los certificados SSL. Por favor, verifique.  │"
        echo "└─────────────────────────────────────────────────────────────────┘"
        exit 1
    fi
    ;;
  no)
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│  No se activarán los certificados SSL. Continuando con el script.  │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    ;;
  *)
    echo "┌─────────────────────────────────────────────┐"
    echo "│  Respuesta no válida. Saliendo del script.  │"
    echo "└─────────────────────────────────────────────┘"
    exit 1
    ;;
esac



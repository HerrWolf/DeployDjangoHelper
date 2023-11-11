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
        ;;
    2)
        db_engine="postgres"
        ;;
    *)
        echo "┌──────────────────────────────────────────┐"
        echo "│  Opción no válida. Saliendo.             │"
        echo "└──────────────────────────────────────────┘"
        exit 1
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

echo "┌───────────────────────────────────┐"
echo "│  Creando archivo gunicorn_start.  │"
echo "└───────────────────────────────────┘"

# Añadir al script main.sh
gunicorn_script="#!/bin/bash

NAME=\"$project_name_app\"
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
  --log-level=debug \\
  --log-file=-
"

# Escribir al archivo gunicorn_start
echo "$gunicorn_script" | sudo tee $project_dir/bin/gunicorn_start >/dev/null

# Dar permisos de ejecución al archivo gunicorn_start
sudo chmod u+x $project_dir/bin/gunicorn_start

# Verificar e instalar Supervisor
if ! command -v supervisorctl &>/dev/null; then
    echo "Supervisor no está instalado. Instalando..."
    sudo apt-get install -y supervisor

    if [ $? -ne 0 ]; then
        echo "Error al instalar Supervisor. ¿Desea intentar nuevamente? (si/no)"
        read try_again
        case $try_again in
            si)
                sudo apt-get install -y supervisor
                ;;
            no)
                echo "No se instalará Supervisor. Saliendo del script."
                exit 1
                ;;
            *)
                echo "Por favor, responda con 'si' o 'no'."
                ;;
        esac
    else
        echo "Supervisor ha sido instalado correctamente."
    fi
else
    echo "Supervisor ya está instalado."
fi

# Crear archivo de configuración de supervisor


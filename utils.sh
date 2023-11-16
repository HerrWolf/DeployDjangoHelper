# Función para verificar y manejar errores en la instalación de paquetes
function handle_package_installation() {
    local package_name="$1"

    # Intentar instalar el paquete automáticamente
    install_package "$package_name"
    while [ $? -ne 0 ]; do
        # La instalación automática falló, preguntar si quieren volver a intentarlo
        echo "Error al instalar $package_name. ¿Desea intentar instalarlo nuevamente? (si/no)"
        read -r reinstall

        case $reinstall in
            si)
                install_package "$package_name"
                ;;
            no)
                echo "Deteniendo el script. Verifica y vuelve a intentarlo."
                exit 1
                ;;
            *)
                echo "Por favor, responda con 'si' o 'no'."
                ;;
        esac
    done
}

function install_package() {
    local package_name="$1"

    sudo apt install -y "$package_name"
    if [ $? -ne 0 ]; then
        echo "Error al instalar $package_name."
        return 1
    else
        echo "$package_name ha sido instalado correctamente."
        return 0
    fi
}

function delete_project_directory() {
    read -p "¿Desea eliminar el directorio del proyecto? (si/no): " delete_project
    case $delete_project in
        si)
            sudo rm -r "$project_dir"
            echo "Directorio del proyecto eliminado. Saliendo del script."
            exit 1
            ;;
        no)
            echo "Saliendo del script."
            exit 1
            ;;
        *)
            delete_project_directory
            ;;
    esac
}

function configure_mysql_user() {
    if ! dpkg -l | grep -q "mysql"; then
        sudo apt-get install -y mysql-server
        mysql_root_password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
        sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';"
        echo "┌──────────────────────────────────────────────────────────────────────┐"
        echo "│  La contraseña de root en MySQL es: $mysql_root_password             │"
        echo "└──────────────────────────────────────────────────────────────────────┘"
    fi
}

function configure_postgres_user() {
    if ! dpkg -l | grep -q "postgresql"; then
        sudo apt-get install -y postgresql
        postgres_root_password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
        echo "ALTER USER postgres WITH PASSWORD '$postgres_root_password';" > temp_file.sql
        sudo -u postgres psql -f temp_file.sql
        rm temp_file.sql
        echo "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo "│  La contraseña de root en PostgreSQL es: $postgres_root_password             │"
        echo "└──────────────────────────────────────────────────────────────────────────────┘"
    fi
}

function create_database_user() {
    local db_user="$project_name_user"
    local db_password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
    local db_name="$1"
    
    if [ "$db_engine" = "mysql" ]; then
        sudo mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';"
        sudo mysql -e "CREATE DATABASE $db_name;"
        sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
        echo "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo "│  Nombre de la base de datos: $db_name                                        │"
        echo "│  Usuario de la base de datos: $db_user                                       │"
        echo "│  Contraseña: $db_password                                                    │"
        echo "└──────────────────────────────────────────────────────────────────────────────┘"
    elif [ "$db_engine" = "postgres" ]; then
        sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_password';"
        sudo -u postgres psql -c "CREATE DATABASE $db_name OWNER $db_user;"
        echo "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo "│  Nombre de la base de datos: $db_name                                        │"
        echo "│  Usuario de la base de datos: $db_user                                       │"
        echo "│  Contraseña: $db_password                                                    │"
        echo "└──────────────────────────────────────────────────────────────────────────────┘"
    fi
}

function verify_project_start() {
    local retries=0
    local max_retries=3

    while [ $retries -lt $max_retries ]; do
        # Realizar la verificación del proyecto
        # ...

        if [ verificación fallida ]; then
            echo "No se pudo iniciar el proyecto después de $retries intentos. Revisa manualmente."

            read -p "¿Has verificado el archivo gunicorn_start? ¿Quieres volver a intentar la verificación? (si/no): " verification_option

            case $verification_option in
                si)
                    # Volver a realizar la verificación
                    # ...
                    ;;
                no)
                    echo "Continuando con el script..."
                    return 1  # Retornar un estado de falla
                    ;;
                *)
                    echo "Respuesta no válida. Continuando con el script..."
                    return 1  # Retornar un estado de falla
                    ;;
            esac

            ((retries++))
        else
            return 0  # Retornar un estado exitoso
        fi
    done

    echo "No se pudo iniciar el proyecto después de $retries intentos. Revisa manualmente."
    return 1  # Retornar un estado de falla
}


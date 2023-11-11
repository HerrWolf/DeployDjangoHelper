# Función para verificar y manejar errores en la instalación de paquetes
function handle_package_installation() {
    package_name="$1"
    while true; do
        echo "$package_name no está instalado. ¿Desea intentar instalarlo nuevamente? (si/no)"
        read reinstall
        case $reinstall in
            si)
                sudo apt install -y "$package_name"
                if [ $? -ne 0 ]; then
                    echo "Error al instalar $package_name. Verifica y vuelve a intentarlo."
                else
                    echo "$package_name ha sido instalado correctamente."
                    break
                fi
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
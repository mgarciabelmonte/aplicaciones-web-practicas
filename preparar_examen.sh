#!/bin/bash
# =====================================================================
#  preparar_examen.sh  ·  Aplicaciones Web · 2º SMR
#
#  Deja Apache en estado limpio para empezar el examen:
#    1. Guarda una copia de seguridad de lo que hay (por si acaso).
#    2. Elimina los sitios de Apache (sites-available y sites-enabled).
#    3. Vacía /var/www/html.
#    4. Deja disponible, pero SIN habilitar, el sitio por defecto.
#
#  Uso:  sudo bash preparar_examen.sh
# =====================================================================

APACHE=/etc/apache2
WWWROOT=/var/www
WWW=/var/www/html
COPIA=/var/backups/apache-antes-del-examen-$(date +%Y%m%d-%H%M%S).tgz

# --- Comprobaciones de seguridad: no hacer nada si algo no cuadra ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse con sudo:  sudo bash $0"
  exit 1
fi
if [ ! -d "$APACHE/sites-available" ] || [ ! -d "$APACHE/sites-enabled" ]; then
  echo "No se encuentra la configuración de Apache en esta máquina."
  echo "No se ha cambiado nada. ¿Estás en la máquina virtual correcta?"
  exit 1
fi

echo "== Preparando el servidor para el examen =="

# --- 1. Copia de seguridad ---
echo "1/4  Copia de seguridad en: $COPIA"
mkdir -p /var/backups
tar -czf "$COPIA" "$APACHE/sites-available" "$APACHE/sites-enabled" "$WWWROOT" 2>/dev/null \
  || echo "     (aviso: la copia de seguridad no se ha podido completar)"

# --- 2. Eliminar los sitios de Apache ---
echo "2/4  Eliminando los sitios de Apache"
find "$APACHE/sites-enabled"   -mindepth 1 -delete
find "$APACHE/sites-available" -mindepth 1 -delete

# --- 3. Vaciar la carpeta web por defecto ---
echo "3/4  Vaciando $WWW"
mkdir -p "$WWW"
find "$WWW" -mindepth 1 -delete

# --- 4. Recrear el sitio por defecto (disponible, NO habilitado) ---
echo "4/4  Recreando 000-default.conf (sin habilitar)"
cat > "$APACHE/sites-available/000-default.conf" <<'FIN'
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
FIN

# --- Reiniciar Apache para que no quede nada cargado en memoria ---
if systemctl restart apache2 2>/dev/null; then
  echo "Apache reiniciado correctamente."
else
  echo "Aviso: Apache no se ha podido reiniciar. Díselo al profesor."
fi

echo
echo "Listo. Sitios habilitados ahora mismo:"
ls -A "$APACHE/sites-enabled" | sed 's/^/   /'
[ -z "$(ls -A "$APACHE/sites-enabled")" ] && echo "   (ninguno)"

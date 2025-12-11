# ------------------------------
# 3. Setup LBU
# ------------------------------
echo ">>> Setting up LBU to store configs on /media/usb or /media/sda1"
LBU_DIR="/var"

sed -i '
/^LBU_BACKUPDIR=/{
  s|^LBU_BACKUPDIR=.*|LBU_BACKUPDIR='"$LBU_DIR"'|
  b
}
$ a\
LBU_BACKUPDIR='"$LBU_DIR"'
' /etc/lbu/lbu.conf

# ------------------------------
# 4. Setup apk cache
# ------------------------------
echo ">>> Setting up apk cache on /var/cache/apk"
mkdir -p /var/cache/apk
ln -s /var/cache/apk /etc/apk/cache

if [ -L "$ROOT"/etc/apk/cache ]; then
  apk cache sync
fi

# ------------------------------
# 5. Finished
# ------------------------------
echo "=============================================="
echo " Alpine linux in diskless mode on single disk is ready!"
echo "=============================================="

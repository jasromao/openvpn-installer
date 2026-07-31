#!/bin/bash
set -e

echo "=========================================="
echo "   OPENVPN INSTALLER"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo "Execute como root:"
    echo "sudo bash"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo
echo "[1/5] Atualizar o sistema..."
apt-get update

echo
echo "[2/5] Instalar dependências..."
apt-get install -y \
openvpn \
easy-rsa \
iptables \
curl \
wget \
tar \
unzip

cd /root

echo
echo "[3/5] Descarregar backup..."
wget -O backup-openvpn.tar.gz \
https://raw.githubusercontent.com/jasromao/openvpn-installer/main/backup-openvpn.tar.gz

echo
echo "[4/5] Descarregar script de restauro..."
wget -O restaurar-openvpn.sh \
https://raw.githubusercontent.com/jasromao/openvpn-installer/main/restaurar-openvpn.sh

chmod +x restaurar-openvpn.sh

echo
echo "[5/5] Restaurar servidor..."
bash restaurar-openvpn.sh

echo
echo "=========================================="
echo " INSTALAÇÃO CONCLUÍDA"
echo "=========================================="
echo
echo "Reinicie o servidor:"
echo
echo "sudo reboot"

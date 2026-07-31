#!/bin/bash
set -e

echo "========================================="
echo " RESTAURO OPENVPN"
echo "========================================="

cd /root

tar -xzf backup-openvpn.tar.gz

if [ -f backup-openvpn.tar.gz ]; then
    echo "Backup extraído."
else
    echo "Erro ao extrair o backup."
    exit 1
fi

if [ -f restaurar-openvpn ]; then
    chmod +x restaurar-openvpn
    ./restaurar-openvpn
elif [ -f restaurar-openvpn.sh ]; then
    chmod +x restaurar-openvpn.sh
    ./restaurar-openvpn.sh
else
    echo "Script de restauro não encontrado."
    exit 1
fi

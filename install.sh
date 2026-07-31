#!/bin/bash
set -e
echo "======================================="
echo "  INSTALADOR OPENVPN AUTOMÁTICO"
echo "======================================="

apt update
apt install -y curl wget unzip

echo
echo "Instalação concluída."
echo
echo "Em seguida será descarregado e restaurado o backup."

#!/bin/bash
set -e

echo "========================================="
echo " INSTALAÇÃO OPENVPN AUTOMÁTICA"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y curl wget unzip tar openvpn easy-rsa iptables

cd /root

echo
echo "A descarregar o backup..."

wget -O backup-openvpn.tar.gz https://raw.githubusercontent.com/jasromao/openvpn-installer/main/backup-openvpn.tar.gz

echo
echo "A restaurar o backup..."

tar -xzf backup-openvpn.tar.gz

chmod +x restaurar-openvpn.sh

./restaurar-openvpn.sh

echo
echo "========================================="
echo " INSTALAÇÃO CONCLUÍDA"
echo "========================================="
echo
echo "Reinicie o Raspberry:"
echo
echo "sudo reboot"

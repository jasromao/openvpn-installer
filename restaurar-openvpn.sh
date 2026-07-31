#!/bin/bash
set -e

echo "========================================="
echo " RESTAURO OPENVPN"
echo "========================================="

cd /root

echo "[1/6] Extrair backup..."
tar -xzf backup-openvpn.tar.gz

echo "[2/6] Restaurar /etc/openvpn..."
cp -a etc/openvpn /etc/

echo "[3/6] Restaurar scripts..."
mkdir -p /usr/local/sbin
cp -a usr/local/sbin/* /usr/local/sbin/
chmod +x /usr/local/sbin/*

echo "[4/6] Ativar IP Forward..."
sysctl -w net.ipv4.ip_forward=1
grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || \
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

echo "[5/6] Restaurar regras NAT..."
iptables-restore < informacoes/iptables.rules || true

echo "[6/6] Ativar OpenVPN..."
systemctl enable openvpn-server@manual
systemctl restart openvpn-server@manual

echo
echo "========================================="
echo " RESTAURO CONCLUÍDO"
echo "========================================="
echo
echo "Reinicie o sistema:"
echo
echo "sudo reboot"

#!/bin/bash
set -euo pipefail

VPN_REDE="10.9.0.0/24"
SERVICO="openvpn-server@manual"
DATA=$(date +"%Y-%m-%d_%H-%M-%S")
TEMP="/tmp/restauro-openvpn-$DATA"

echo
echo "========================================"
echo " RESTAURO COMPLETO OPENVPN"
echo "========================================"
echo

if [ "$EUID" -ne 0 ]; then
    echo "Execute este script com sudo."
    exit 1
fi

BACKUP="/root/backup-openvpn.tar.gz"

echo "A utilizar o backup:"
echo "$BACKUP"

if [ ! -f "$BACKUP" ]; then
    echo "O ficheiro de backup não existe:"
    echo "$BACKUP"
    exit 1
fi

if ! tar -tzf "$BACKUP" >/dev/null 2>&1; then
    echo "O ficheiro indicado não é um backup .tar.gz válido."
    exit 1
fi

echo "Backup encontrado:"
echo "$BACKUP"
echo

echo "A instalar os programas necessários..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openvpn \
    easy-rsa \
    iptables-persistent \
    netfilter-persistent \
    tar

mkdir -p "$TEMP"

echo "A extrair o backup..."
tar -xzf "$BACKUP" -C "$TEMP"

if [ ! -f "$TEMP/etc/openvpn/server/manual.conf" ]; then
    echo "Erro: não foi encontrado manual.conf dentro do backup."
    rm -rf "$TEMP"
    exit 1
fi

echo "A guardar a configuração existente da VPS nova..."

mkdir -p "/root/openvpn-antes-do-restauro-$DATA"

if [ -d /etc/openvpn ]; then
    cp -a /etc/openvpn \
        "/root/openvpn-antes-do-restauro-$DATA/" 2>/dev/null || true
fi

if [ -f /usr/local/sbin/criar-cliente-ovpn ]; then
    cp -a /usr/local/sbin/criar-cliente-ovpn \
        "/root/openvpn-antes-do-restauro-$DATA/" 2>/dev/null || true
fi

echo "A restaurar a configuração OpenVPN..."

mkdir -p /etc/openvpn/server
cp -a "$TEMP/etc/openvpn/server/manual.conf" \
    /etc/openvpn/server/manual.conf

if [ -d "$TEMP/etc/openvpn/manual-easy-rsa" ]; then
    rm -rf /etc/openvpn/manual-easy-rsa
    cp -a "$TEMP/etc/openvpn/manual-easy-rsa" \
        /etc/openvpn/manual-easy-rsa
fi

if [ -d "$TEMP/etc/openvpn/ccd" ]; then
    rm -rf /etc/openvpn/ccd
    cp -a "$TEMP/etc/openvpn/ccd" \
        /etc/openvpn/ccd
fi

echo "A restaurar o gestor de clientes..."

if [ -f "$TEMP/usr/local/sbin/criar-cliente-ovpn" ]; then
    cp -a "$TEMP/usr/local/sbin/criar-cliente-ovpn" \
        /usr/local/sbin/criar-cliente-ovpn

    chmod 755 /usr/local/sbin/criar-cliente-ovpn
fi

if [ -f "$TEMP/usr/local/sbin/criar-cliente-ovpn.bak" ]; then
    cp -a "$TEMP/usr/local/sbin/criar-cliente-ovpn.bak" \
        /usr/local/sbin/criar-cliente-ovpn.bak
fi
echo "A copiar certificados para o servidor..."

mkdir -p /etc/openvpn/server/manual

cp /etc/openvpn/manual-easy-rsa/pki/ca.crt /etc/openvpn/server/manual/
cp /etc/openvpn/manual-easy-rsa/pki/issued/server.crt /etc/openvpn/server/manual/
cp /etc/openvpn/manual-easy-rsa/pki/private/server.key /etc/openvpn/server/manual/
cp /etc/openvpn/manual-easy-rsa/pki/dh.pem /etc/openvpn/server/manual/
cp /etc/openvpn/manual-easy-rsa/pki/ta.key /etc/openvpn/server/manual/

chown root:root /etc/openvpn/server/manual/*
chmod 600 /etc/openvpn/server/manual/server.key
chmod 600 /etc/openvpn/server/manual/ta.key
echo "A corrigir permissões..."

chown -R root:root /etc/openvpn

chmod 755 /etc/openvpn
chmod 755 /etc/openvpn/server
chmod 600 /etc/openvpn/server/manual.conf

if [ -d /etc/openvpn/ccd ]; then
    chmod 755 /etc/openvpn/ccd
    find /etc/openvpn/ccd -type f -exec chmod 644 {} \;
fi

if [ -d /etc/openvpn/manual-easy-rsa ]; then
    chmod 700 /etc/openvpn/manual-easy-rsa
fi

echo "A restaurar os perfis dos clientes..."

if id ubuntu >/dev/null 2>&1; then
    mkdir -p /home/ubuntu

    if [ -d "$TEMP/home/ubuntu" ]; then
        find "$TEMP/home/ubuntu" -maxdepth 1 -type f -name "*.ovpn" \
            -exec cp -a {} /home/ubuntu/ \;
    fi

    chown ubuntu:"$(id -gn ubuntu)" /home/ubuntu/*.ovpn \
        2>/dev/null || true

    chmod 600 /home/ubuntu/*.ovpn \
        2>/dev/null || true
fi

echo "A ativar o encaminhamento IPv4..."

cat > /etc/sysctl.d/99-openvpn-forward.conf <<EOF
net.ipv4.ip_forward=1
EOF

sysctl --system >/dev/null

INTERFACE_INTERNET=$(ip route show default |
    awk '/default/ {print $5; exit}')

if [ -z "$INTERFACE_INTERNET" ]; then
    echo "Erro: não foi possível detetar a interface de Internet."
    rm -rf "$TEMP"
    exit 1
fi

echo "Interface de Internet detetada: $INTERFACE_INTERNET"

echo "A configurar NAT e encaminhamento..."

iptables -t nat -C POSTROUTING \
    -s "$VPN_REDE" \
    -o "$INTERFACE_INTERNET" \
    -j MASQUERADE 2>/dev/null ||
iptables -t nat -A POSTROUTING \
    -s "$VPN_REDE" \
    -o "$INTERFACE_INTERNET" \
    -j MASQUERADE

iptables -C FORWARD \
    -s "$VPN_REDE" \
    -j ACCEPT 2>/dev/null ||
iptables -A FORWARD \
    -s "$VPN_REDE" \
    -j ACCEPT

iptables -C FORWARD \
    -d "$VPN_REDE" \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT 2>/dev/null ||
iptables -A FORWARD \
    -d "$VPN_REDE" \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

netfilter-persistent save >/dev/null

echo "A verificar o ficheiro de configuração..."

openvpn --config /etc/openvpn/server/manual.conf \
    --test-crypto >/dev/null 2>&1 || true

echo "A ativar o serviço OpenVPN..."

systemctl daemon-reload
systemctl enable "$SERVICO"
systemctl restart "$SERVICO"

sleep 3

echo
if systemctl is-active --quiet "$SERVICO"; then
    echo "========================================"
    echo " RESTAURO CONCLUÍDO COM SUCESSO"
    echo "========================================"
    echo
    echo "Serviço: ATIVO"
    echo "Rede VPN: $VPN_REDE"
    echo "Interface Internet: $INTERFACE_INTERNET"
    echo
    echo "Gestor de clientes:"
    echo "sudo criar-cliente-ovpn"
    echo
else
    echo "========================================"
    echo " O SERVIÇO NÃO INICIOU"
    echo "========================================"
    echo
    echo "Consulta o erro com:"
    echo "sudo systemctl status $SERVICO --no-pager"
    echo
    echo "E:"
    echo "sudo journalctl -u $SERVICO -n 100 --no-pager"
    echo
    rm -rf "$TEMP"
    exit 1
fi

rm -rf "$TEMP"

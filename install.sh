#!/bin/bash
set -e

echo "=========================================="
echo "        OPENVPN INSTALLER"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo "Execute com sudo."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo
echo "[1/6] Atualizar o sistema..."
apt-get update

echo
echo "[2/6] Instalar dependências..."
apt-get install -y \
    openvpn \
    easy-rsa \
    iptables \
    curl \
    wget \
    tar \
    unzip

echo
echo "[3/6] Credenciais GitHub"

read -p "Utilizador GitHub: " GITHUB_USER
read -rsp "GitHub Token: " GITHUB_TOKEN
echo

cd /root

echo
echo "[4/6] Descarregar backup..."

curl -fL \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -o backup-openvpn.tar.gz \
  "https://raw.githubusercontent.com/${GITHUB_USER}/openvpn-backup/main/backup-openvpn.tar.gz"

if [ ! -f backup-openvpn.tar.gz ]; then
    echo
    echo "Erro ao descarregar o backup."
    exit 1
fi

echo
echo "[5/6] Descarregar script de restauro..."

curl -fL \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -o restaurar-openvpn.sh \
  "https://raw.githubusercontent.com/${GITHUB_USER}/openvpn-backup/main/restaurar-openvpn.sh"

if [ ! -f restaurar-openvpn.sh ]; then
    echo
    echo "Erro ao descarregar o script de restauro."
    exit 1
fi

chmod +x restaurar-openvpn.sh

unset GITHUB_TOKEN
unset GITHUB_USER

echo
echo "[6/6] Restaurar servidor..."

bash restaurar-openvpn.sh

echo
echo "=========================================="
echo " INSTALAÇÃO CONCLUÍDA"
echo "=========================================="
echo
echo "Reinicie o servidor:"
echo
echo "sudo reboot"

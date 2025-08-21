#!/bin/bash
# installparanaue.sh - Instala o kit de stress para testes de logs (Multi-distro)

echo "🔧 Instalando kit de ferramentas..."
echo "------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Não foi possível detectar a distribuição"
    exit 1
fi

# Instala pacotes conforme a distro
case $OS in
    ubuntu|debian)
        echo "🔄 Atualizando sistema (Ubuntu/Debian)..."
        sudo apt-get update && sudo apt-get upgrade -y -qq
        sudo apt-get install -y stress-ng golang-go htop
        ;;
    rhel|centos|fedora)
        echo "🔄 Atualizando sistema (RHEL/CentOS/Fedora)..."
        sudo yum update -y -q  # Update com upgrade implícito no yum
        sudo yum install -y stress-ng golang htop
        ;;
    *)
        echo "❌ Distribuição não suportada: $OS"
        exit 1
        ;;
esac

# Prepara ambiente (funciona em qualquer distro)
mkdir -p ~/logs_triagem
cd ~/logs_triagem

# Cria script de teste universal
cat > stress.sh << 'EOF'
#!/bin/bash
echo "🚦 Gerando carga no sistema ($(hostname))..."
stress-ng --cpu 2 --timeout 20s
stress-ng --vm 1 --vm-bytes 512M --timeout 15s
echo "✅ Carga concluída em $(date)"
EOF

chmod +x stress.sh

echo "✅ Instalação concluída em $OS!"
echo "➡️  Execute: cd ~/logs_triagem && ./stress.sh"
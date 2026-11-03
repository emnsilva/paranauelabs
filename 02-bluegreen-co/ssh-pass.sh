for ip in 192.168.122.122 192.168.122.126 192.168.122.161; do
  echo ">>> Configurando $ip <<<"
  # Remove a chave antiga (se existir) para evitar conflito
  ssh-keygen -R $ip 2>/dev/null || true
  # Copia a chave SSH
  ssh-copy-id -o StrictHostKeyChecking=no alpine@$ip
  # Configura o sudo sem senha
  ssh -t -o StrictHostKeyChecking=no alpine@$ip "echo 'alpine ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alpine > /dev/null && sudo chmod 0440 /etc/sudoers.d/alpine"
done
echo "✅ Pronto! Agora o SSH e o Sudo estão sem senha."
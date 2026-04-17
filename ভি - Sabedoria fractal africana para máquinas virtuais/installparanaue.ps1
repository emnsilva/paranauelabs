<#
.SYNOPSIS
    Prepara Windows Server para OpenStack com Hyper-V
.NOTES
    Executar como Administrador
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$FlagFile = "$env:TEMP\openstack_hyperv_installed.txt"

# Fase 1: Instalar Hyper-V e reiniciar
if (-not (Test-Path $FlagFile)) {
    Write-Host ">>> FASE 1: Instalando Hyper-V..." -ForegroundColor Green
    
    $hyperv = Get-WindowsFeature -Name Hyper-V
    if (-not $hyperv.Installed) {
        Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
    }
    
    # Marcar que já instalamos o Hyper-V
    New-Item -Path $FlagFile -ItemType File -Force
    Write-Host ">>> Reiniciando o servidor..." -ForegroundColor Yellow
    Restart-Computer -Force
    exit
}

# Fase 2: Configurar o resto após o reboot
Write-Host ">>> FASE 2: Configurando ambiente..." -ForegroundColor Green

# Configurar WinRM
Write-Host ">>> Configurando WinRM..."
winrm quickconfig -quiet -force
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM" dir=in localport=5986 protocol=TCP action=allow

# Criar Virtual Switch
$switchName = "openstack-switch"
if (-not (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue)) {
    Write-Host ">>> Criando Virtual Switch..."
    $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -notlike "*Loopback*"} | Select-Object -First 1
    if ($adapter) {
        New-VMSwitch -Name $switchName -NetAdapterName $adapter.Name -AllowManagementOS $true
    } else {
        New-VMSwitch -Name $switchName -SwitchType Internal
    }
}

# Configurar iSCSI
Write-Host ">>> Configurando iSCSI..."
Set-Service -Name MSiSCSI -StartupType Automatic
Start-Service MSiSCSI

# Instalar Python
Write-Host ">>> Instalando Python 2.7..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install python2 -y --version=2.7.18 --x86

# Limpar flag
Remove-Item $FlagFile -Force

Write-Host ""
Write-Host ">>> CONCLUIDO!" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:"
Write-Host "1. Baixe o instalador da Cloudbase:"
Write-Host "   https://cloudbase.it/downloads/CloudbaseOpenStackSetup.exe"
Write-Host ""
Write-Host "2. Configure o controller Linux com:"
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress
Write-Host "   IP: $ip"
Write-Host "   Hostname: $env:COMPUTERNAME"
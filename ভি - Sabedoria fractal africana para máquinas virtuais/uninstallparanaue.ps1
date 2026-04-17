<#
.SYNOPSIS
    Remove completamente tudo que foi instalado pelo prepare-openstack.ps1
.DESCRIPTION
    Remove Hyper-V, configurações de WinRM, Virtual Switch, iSCSI, Python e Chocolatey
.NOTES
    Executar como Administrador
    ATENÇÃO: Isso removerá TODAS as VMs e configurações do Hyper-V!
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ">>> REMOVENDO COMPLETAMENTE O OPENSTACK DO WINDOWS..." -ForegroundColor Red
Write-Host ">>> ATENÇÃO: Isso removerá TODAS as VMs do Hyper-V!" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Digite 'SIM' para confirmar a remoção completa"
if ($confirm -ne "SIM") {
    Write-Host ">>> Operação cancelada."
    exit
}

Write-Host ""

# 1. Parar e remover serviços do OpenStack (se existirem)
Write-Host ">>> Parando serviços do OpenStack..."
$services = @("nova-compute", "neutron-hyperv-agent", "CloudbaseInit")
foreach ($service in $services) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        sc.exe delete $service 2>$null
        Write-Host "    Serviço $service removido"
    } catch {
        Write-Host "    Serviço $service não encontrado"
    }
}

# 2. Remover instalador da Cloudbase (se existir)
Write-Host ">>> Removendo Cloudbase OpenStack..."
$uninstallers = @(
    "Cloudbase OpenStack*",
    "Cloudbase Nova Compute*",
    "Cloudbase Hyper-V Compute*"
)
foreach ($uninstaller in $uninstallers) {
    $app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like $uninstaller}
    if ($app) {
        $app.Uninstall() | Out-Null
        Write-Host "    $($app.Name) removido"
    }
}

# 3. Remover Python 2.7
Write-Host ">>> Removendo Python 2.7..."
$python = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Python 2.7*"}
if ($python) {
    $python.Uninstall() | Out-Null
    Write-Host "    Python 2.7 removido"
}

# 4. Remover Chocolatey
Write-Host ">>> Removendo Chocolatey..."
Remove-Item -Path "$env:ProgramData\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.chocolatey" -Recurse -Force -ErrorAction SilentlyContinue

# 5. Remover Virtual Switch
Write-Host ">>> Removendo Virtual Switch..."
$switchName = "openstack-switch"
$switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if ($switch) {
    Remove-VMSwitch -Name $switchName -Force
    Write-Host "    Virtual Switch '$switchName' removido"
}

# 6. Remover TODAS as VMs do Hyper-V
Write-Host ">>> Removendo todas as VMs do Hyper-V..."
$vms = Get-VM
foreach ($vm in $vms) {
    Stop-VM -Name $vm.Name -Force -ErrorAction SilentlyContinue
    Remove-VM -Name $vm.Name -Force
    Write-Host "    VM '$($vm.Name)' removida"
}

# 7. Remover Hyper-V (a role)
Write-Host ">>> Removendo Hyper-V..."
Uninstall-WindowsFeature -Name Hyper-V -IncludeManagementTools
Write-Host "    Hyper-V removido (requer reboot para concluir)"

# 8. Remover configurações do WinRM
Write-Host ">>> Removendo configurações do WinRM..."
netsh advfirewall firewall delete rule name="WinRM" 2>$null
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS 2>$null

# 9. Remover iSCSI
Write-Host ">>> Removendo iSCSI..."
Stop-Service -Name MSiSCSI -Force -ErrorAction SilentlyContinue
Set-Service -Name MSiSCSI -StartupType Disabled

# 10. Remover diretórios e arquivos residuais
Write-Host ">>> Removendo arquivos residuais..."
$paths = @(
    "$env:ProgramFiles\Cloudbase Solutions",
    "$env:ProgramFiles\Python*",
    "$env:ProgramData\Cloudbase",
    "$env:ProgramData\Python",
    "$env:USERPROFILE\.cloudbase",
    "$env:TEMP\Cloudbase*",
    "$env:TEMP\openstack*",
    "C:\OpenStack"
)
foreach ($path in $paths) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    $path removido"
    }
}

# 11. Remover variáveis de ambiente
Write-Host ">>> Removendo variáveis de ambiente..."
$envVars = @("PYTHONPATH", "CLOUDBASE_HOME")
foreach ($var in $envVars) {
    [Environment]::SetEnvironmentVariable($var, $null, "Machine")
    [Environment]::SetEnvironmentVariable($var, $null, "User")
}

Write-Host ""
Write-Host ">>> REMOÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host ""
Write-Host "O que foi removido:"
Write-Host "  [X] Hyper-V (role)"
Write-Host "  [X] Virtual Switch"
Write-Host "  [X] Todas as VMs"
Write-Host "  [X] Cloudbase OpenStack"
Write-Host "  [X] Python 2.7"
Write-Host "  [X] Chocolatey"
Write-Host "  [X] WinRM (configurações extras)"
Write-Host "  [X] iSCSI (serviço desabilitado)"
Write-Host "  [X] Arquivos residuais"
Write-Host ""
Write-Host ">>> Para completar a limpeza, REINICIE O SERVIDOR!" -ForegroundColor Yellow
Write-Host ""

$reboot = Read-Host "Deseja reiniciar agora? (S/N)"
if ($reboot -eq "S" -or $reboot -eq "s") {
    Restart-Computer -Force
}
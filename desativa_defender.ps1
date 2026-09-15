<#
.SYNOPSIS
    Desativa Windows Defender e telemetria em ambiente de teste (VM).
.DESCRIPTION
    Script para laboratório isolado. Executa:
      - Verificação de Tamper Protection
      - Desativação do Windows Defender (preferências, serviços, registro)
      - Desativação de telemetria (DiagTrack, dmwappushservice, WerSvc)
      - Desabilitação de tarefas agendadas de telemetria
      - Verificação final do estado
.NOTES
    Execute como Administrador. Requer PowerShell 5.1+.
    Recomendado: criar snapshot/ponto de restauração ANTES de executar.
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

function Write-Section($text) {
    Write-Host "`n===== $text =====" -ForegroundColor Cyan
}
function Write-OK($text)   { Write-Host "[OK]   $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "[AVISO] $text" -ForegroundColor Yellow }
function Write-Err($text)  { Write-Host "[ERRO] $text" -ForegroundColor Red }

# ---------------------------------------------------------------
# 0. Snapshot informativo + verificação de Tamper Protection
# ---------------------------------------------------------------
Write-Section "0. Verificação inicial"

$isVM = (Get-CimInstance Win32_ComputerSystem).Model -match 'Virtual|VMware|VirtualBox|Hyper-V|QEMU|KVM'
if (-not $isVM) {
    Write-Warn "Não foi detectada uma VM. Abortando por segurança."
    Write-Warn "Se tiver certeza, remova a checagem 'isVM' do script."
    return
}
Write-OK "Ambiente virtual detectado."

try {
    $mpStatus = Get-MpComputerStatus -ErrorAction Stop
    if ($mpStatus.TamperProtectionSource -ne 'None' -and
        $mpStatus.TamperProtectionSource -ne $null) {
        Write-Warn "Tamper Protection ativa (fonte: $($mpStatus.TamperProtectionSource))."
        Write-Warn "Tentando desativar via Set-MpPreference (só funciona em modo troubleshooting)..."
        try {
            Set-MpPreference -DisableTamperProtection $true -ErrorAction Stop
            Write-OK "Tamper Protection desativada."
        } catch {
            Write-Err "Não foi possível desativar Tamper Protection automaticamente."
            Write-Err "Desative manualmente em: Segurança do Windows > Proteção contra vírus e ameaças > Gerenciar configurações."
            Write-Warn "Continuando — algumas alterações podem ser revertidas."
        }
    } else {
        Write-OK "Tamper Protection já está desativada ou indisponível."
    }
} catch {
    Write-Warn "Não foi possível consultar status do Defender: $($_.Exception.Message)"
}

# ---------------------------------------------------------------
# 1. Desativar preferências do Windows Defender
# ---------------------------------------------------------------
Write-Section "1. Preferências do Windows Defender"

$mpPrefs = @{
    'DisableRealtimeMonitoring'       = $true
    'DisableBehaviorMonitoring'       = $true
    'DisableIOAVProtection'           = $true
    'DisableScriptScanning'           = $true
    'DisableArchiveScanning'          = $true
    'DisableIntrusionPreventionSystem'= $true
    'DisableAntiSpyware'              = $true   # pode falhar em versões novas
    'DisableAntiVirus'                = $true   # pode falhar em versões novas
    'DisableCatchupFullScan'          = $true
    'DisableCatchupQuickScan'         = $true
    'DisableRemovableDriveScanning'   = $true
    'DisableScanningMappedNetworkDrivesForFullScan' = $true
    'DisableBlockAtFirstSeen'         = $true
    'SubmitSamplesConsent'            = 2       # 2 = Never send
    'MAPSReporting'                   = 0       # 0 = Disabled
    'PUAProtection'                   = 0       # 0 = Disabled
    'EnableFileHashComputation'       = $false
    'CloudBlockLevel'                 = 0
}

foreach ($pref in $mpPrefs.GetEnumerator()) {
    try {
        Set-MpPreference -$pref.Key $pref.Value -ErrorAction Stop
        Write-OK "Set-MpPreference -$($pref.Key) $($pref.Value)"
    } catch {
        Write-Warn "Falha em $($pref.Key): $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------
# 2. Desabilitar serviços do Defender e Telemetria
# ---------------------------------------------------------------
Write-Section "2. Serviços (Defender + Telemetria)"

$services = @(
    # Defender
    @{ Name = 'WinDefend';            Desc = 'Windows Defender' }
    @{ Name = 'WdNisSvc';             Desc = 'Network Inspection' }
    @{ Name = 'Sense';                Desc = 'Defender ATP' }
    @{ Name = 'SecurityHealthService';Desc = 'Security Health' }
    @{ Name = 'wscsvc';               Desc = 'Security Center' }
    # Telemetria
    @{ Name = 'DiagTrack';            Desc = 'Connected User Experiences and Telemetry' }
    @{ Name = 'dmwappushservice';     Desc = 'Device Management WAP Push' }
    @{ Name = 'WerSvc';               Desc = 'Windows Error Reporting' }
    @{ Name = 'PcaSvc';               Desc = 'Program Compatibility Assistant' }
)

foreach ($svc in $services) {
    $name = $svc.Name
    $s = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $s) {
        Write-Warn "Serviço '$name' não encontrado."
        continue
    }
    try {
        Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $name -StartupType Disabled -ErrorAction Stop
        Write-OK "$name ($($svc.Desc)) parado e desabilitado."
    } catch {
        Write-Err "$name : $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------
# 3. Registro — políticas do Defender e telemetria
# ---------------------------------------------------------------
Write-Section "3. Chaves de registro"

$regKeys = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender';
       Name = 'DisableAntiSpyware'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender';
       Name = 'DisableAntiVirus';   Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection';
       Name = 'DisableRealtimeMonitoring'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection';
       Name = 'DisableBehaviorMonitoring'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection';
       Name = 'DisableOnAccessProtection'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection';
       Name = 'DisableScanOnRealtimeEnable'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection';
       Name = 'AllowTelemetry'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection';
       Name = 'AllowTelemetry'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting';
       Name = 'Disabled'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection';
       Name = 'MaxTelemetryAllowed'; Value = 0; Type = 'DWord' }
)

foreach ($rk in $regKeys) {
    try {
        if (-not (Test-Path $rk.Path)) {
            New-Item -Path $rk.Path -Force | Out-Null
        }
        New-ItemProperty -Path $rk.Path -Name $rk.Name -Value $rk.Value `
            -PropertyType $rk.Type -Force -ErrorAction Stop | Out-Null
        Write-OK "$($rk.Path)\$($rk.Name) = $($rk.Value)"
    } catch {
        Write-Err "$($rk.Path)\$($rk.Name): $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------
# 4. Desabilitar tarefas agendadas de telemetria
# ---------------------------------------------------------------
Write-Section "4. Tarefas agendadas"

$taskPaths = @(
    '\Microsoft\Windows\Application Experience\*'
    '\Microsoft\Windows\Customer Experience Improvement Program\*'
    '\Microsoft\Windows\Autochk\Proxy'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
    '\Microsoft\Windows\Feedback\Siuf\DmClient'
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    '\Microsoft\Windows\Windows Error Reporting\*'
    '\Microsoft\Windows\Device Information\*'
    '\Microsoft\Windows\CloudExperienceHost\*'
)

foreach ($path in $taskPaths) {
    $tasks = Get-ScheduledTask -TaskPath (Split-Path $path -Parent) -ErrorAction SilentlyContinue |
             Where-Object { $_.TaskPath + $_.TaskName -like $path }
    if (-not $tasks) {
        Write-Warn "Nenhuma tarefa em $path"
        continue
    }
    foreach ($t in $tasks) {
        try {
            Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop | Out-Null
            Write-OK "Desabilitada: $($t.TaskPath)$($t.TaskName)"
        } catch {
            Write-Err "Falha ao desabilitar $($t.TaskPath)$($t.TaskName): $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------
# 5. Desabilitar via sc config (persistência extra)
# ---------------------------------------------------------------
Write-Section "5. sc config (persistência)"

$scServices = @('WinDefend','WdNisSvc','Sense','DiagTrack','dmwappushservice','WerSvc')
foreach ($svc in $scServices) {
    $out = & sc.exe config $svc start= disabled 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "sc config $svc start= disabled"
    } else {
        Write-Warn "sc config $svc : $out"
    }
}

# ---------------------------------------------------------------
# 6. Verificação final
# ---------------------------------------------------------------
Write-Section "6. Verificação final"

try {
    $status = Get-MpComputerStatus -ErrorAction Stop
    if ($status.RealTimeProtectionEnabled) {
        Write-Err "Proteção em tempo real AINDA ATIVA."
    } else {
        Write-OK "Proteção em tempo real desativada."
    }
    if ($status.AntivirusEnabled) {
        Write-Err "Antivírus AINDA ATIVO."
    } else {
        Write-OK "Antivírus desativado."
    }
} catch {
    Write-Warn "Get-MpComputerStatus indisponível: $($_.Exception.Message)"
}

foreach ($svc in @('WinDefend','DiagTrack','dmwappushservice','WerSvc')) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        $state = if ($s.Status -eq 'Stopped') { "OK" } else { "ATIVO" }
        $color = if ($s.Status -eq 'Stopped') { 'Green' } else { 'Red' }
        Write-Host ("[{0}] {1} -> {2} / {3}" -f $state, $svc, $s.Status, $s.StartType) -ForegroundColor $color
    }
}

Write-Host "`n===== Concluído. Reinicie a VM para aplicar todas as alterações. =====" -ForegroundColor Cyan

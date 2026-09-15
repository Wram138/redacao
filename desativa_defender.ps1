Set-MpPreference -DisableRealtimeMonitoring $true -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name 'DisableAntiSpyware' -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name 'DisableAntiVirus' -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name 'ServiceKeepAlive' -Value 0 -PropertyType DWord -Force

<#
.SINOPSE
    Desativa recursos de segurança do Windows para fins de teste.
    Requer execução como Administrador.
.NOTA
    Algumas configurações podem ser revertidas pelo Windows Update ou pela Proteção contra violação.
    Se a Proteção contra violação estiver ativa, desabilite-a manualmente em:
    Configurações > Segurança do Windows > Proteção contra vírus e ameaças > Gerenciar configurações > Proteção contra violação (desligar)
#>

# Verifica se está sendo executado como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    pause
    exit
}

Write-Host "Aplicando alterações..." -ForegroundColor Yellow

# 1. Desabilitar Proteção em Tempo Real do Windows Defender
Try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
    Write-Host "  [OK] Proteção em tempo real desativada"
} Catch {
    Write-Host "  [FALHA] Não foi possível desativar a proteção em tempo real: $_" -ForegroundColor Red
}

# 2. Desabilitar outros componentes do Defender via preferências
Try {
    Set-MpPreference -DisableBehaviorMonitoring $true
    Set-MpPreference -DisableBlockAtFirstSeen $true
    Set-MpPreference -DisableIOAVProtection $true
    Set-MpPreference -DisablePrivacyMode $true
    Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true
    Set-MpPreference -DisableArchiveScanning $true
    Set-MpPreference -DisableIntrusionPreventionSystem $true
    Set-MpPreference -DisableScriptScanning $true
    Set-MpPreference -SubmitSamplesConsent 2  # Nunca enviar amostras
    Set-MpPreference -MAPSReporting 0          # Desabilitar MAPS (nuvem)
    Write-Host "  [OK] Preferências adicionais do Defender configuradas"
} Catch {
    Write-Host "  [FALHA] Erro ao configurar preferências: $_" -ForegroundColor Red
}

# 3. Desabilitar o Windows Defender completamente via Política (registro)
#    Isso desabilita o serviço, mas pode ser reativado se a Proteção contra violação estiver ativa.
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
    Write-Host "  [OK] Política 'DisableAntiSpyware' ativada (Defender desabilitado via registro)"
} Catch {
    Write-Host "  [FALHA] Não foi possível criar a chave de política do Defender: $_" -ForegroundColor Red
}

# 4. Parar e desabilitar serviços relacionados ao Defender
$services = @(
    "WinDefend",      # Windows Defender Antivirus Service
    "WdNisSvc",       # Network Inspection Service
    "Sense",          # Windows Defender Advanced Threat Protection
    "SecurityHealthService" # Segurança do Windows (notificações)
)
foreach ($svc in $services) {
    Try {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled -ErrorAction Stop
        Write-Host "  [OK] Serviço '$svc' parado e desabilitado"
    } Catch {
        Write-Host "  [FALHA] Não foi possível parar/desabilitar o serviço '$svc': $_" -ForegroundColor Red
    }
}

# 5. Desabilitar Telemetria (Coleta de Dados)
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
    # Para versões antigas, pode ser necessário também:
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Telemetria configurada para nível 0 (Segurança)"
} Catch {
    Write-Host "  [FALHA] Erro ao desabilitar telemetria: $_" -ForegroundColor Red
}

# 6. Desabilitar SmartScreen (para Windows, Edge, Store, IE)
#    SmartScreen do Windows
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -Force
    Write-Host "  [OK] SmartScreen do Windows desabilitado"
} Catch {
    Write-Host "  [FALHA] Erro ao desabilitar SmartScreen do Windows: $_" -ForegroundColor Red
}

#    SmartScreen para Microsoft Edge (baseado em Chromium)
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SmartScreenEnabled" -Value 0 -Type DWord -Force
    Write-Host "  [OK] SmartScreen do Edge (Chromium) desabilitado"
} Catch {
    Write-Host "  [AVISO] Não foi possível desabilitar SmartScreen do Edge (talvez não instalado): $_" -ForegroundColor Yellow
}

#    SmartScreen para Internet Explorer
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter" -Name "Enabled" -Value 0 -Type DWord -Force
    Write-Host "  [OK] Filtro de Phishing do IE desabilitado"
} Catch {
    Write-Host "  [AVISO] Falha ao desabilitar filtro do IE: $_" -ForegroundColor Yellow
}

#    SmartScreen para Windows Store
Try {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -Value 0 -Type DWord -Force
    Write-Host "  [OK] SmartScreen da Store desabilitado (usuário atual)"
} Catch {
    Write-Host "  [AVISO] Falha ao desabilitar SmartScreen da Store: $_" -ForegroundColor Yellow
}

# 7. Desabilitar Windows Antimalware (reforço adicional via política)
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware" -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
    Write-Host "  [OK] Política de antimalware desabilitada"
} Catch {
    Write-Host "  [AVISO] Falha ao definir política de antimalware: $_" -ForegroundColor Yellow
}

# 8. Desabilitar notificações da Central de Segurança
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableNotifications" -Value 1 -Type DWord -Force
    Write-Host "  [OK] Notificações de segurança desabilitadas"
} Catch {
    Write-Host "  [AVISO] Falha ao desabilitar notificações: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script concluído. Algumas alterações podem exigir reinicialização para ter efeito completo." -ForegroundColor Green
pause

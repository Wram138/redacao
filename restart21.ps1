# Define a ação: comando shutdown para reiniciar (/r), forçar o fechamento de aplicativos (/f) imediatamente (/t 0)
$Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /f /t 0"

# Define o gatilho: execução diária às 21:00
$Trigger = New-ScheduledTaskTrigger -Daily -At "21:00"

# Define o contexto de segurança: executar como SYSTEM (garante que funcione mesmo sem ninguém logado) com privilégios máximos
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Nome da tarefa
$TaskName = "Reinicio_Diario_21h"

# Registra a tarefa agendada no Windows
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Description "Reinicia a máquina automaticamente todos os dias às 21h." -Force

Write-Host "Tarefa '$TaskName' agendada com sucesso!" -ForegroundColor Green

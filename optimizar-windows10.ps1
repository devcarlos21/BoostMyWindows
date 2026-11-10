# =====================================================================
#  OPTIMIZAR WINDOWS 10 AL MAXIMO PARA JUGAR GTA SA y NFS MW 2005
#  PC: 4 GB RAM / 4 hilos / SSD
#  Ejecutar con EJECUTAR.bat (doble clic). Pide permisos de admin solo.
#  Es AGRESIVO: borra apps, apaga Defender, Update, telemetria, etc.
#  Deja un punto de restauracion y un log en el Escritorio.
# =====================================================================

# --- Auto-elevar a administrador ---
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
try { Start-Transcript -Path "$env:USERPROFILE\Desktop\optimizacion-log.txt" -Force | Out-Null } catch {}

$script:n = 0
function Step($t) { $script:n++; Write-Host ""; Write-Host "[$script:n] $t" -ForegroundColor Cyan }
function Set-Reg($p, $name, $v, $t = 'DWord') {
    try {
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name $name -Value $v -PropertyType $t -Force | Out-Null
    } catch { Write-Host "   (omitido) $p $name" -ForegroundColor DarkYellow }
}

Clear-Host
Write-Host "=== OPTIMIZACION MAXIMA WINDOWS 10 (modo juego) ===" -ForegroundColor Green
Write-Host "Cierra todos los programas. Esto tarda unos 10-20 minutos."
Read-Host "Pulsa ENTER para empezar"

# ---------------------------------------------------------------------
Step "Punto de restauracion"
# ---------------------------------------------------------------------
Enable-ComputerRestore -Drive "C:\"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" "SystemRestorePointCreationFrequency" 0
Checkpoint-Computer -Description "Antes de optimizar para juegos" -RestorePointType MODIFY_SETTINGS

# ---------------------------------------------------------------------
Step "Plan de energia: Maximo rendimiento, sin hibernacion, sin ahorro"
# ---------------------------------------------------------------------
$out = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-String)
if ($out -match '([0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})') { $g = $Matches[1] }
else { $g = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }   # Alto rendimiento (respaldo)
powercfg -setactive $g
# CPU siempre al 100% (sin core parking), sin suspension USB, sin apagar disco/pantalla
powercfg -setacvalueindex $g 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100
powercfg -setacvalueindex $g 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
powercfg -setacvalueindex $g 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -change -disk-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-ac 0
powercfg -setactive $g
powercfg -h off
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0   # sin inicio rapido

# ---------------------------------------------------------------------
Step "Efectos visuales al minimo, mouse sin aceleracion"
# ---------------------------------------------------------------------
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
Set-ItemProperty "HKCU:\Control Panel\Desktop" UserPreferencesMask ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
Set-ItemProperty "HKCU:\Control Panel\Desktop" MenuShowDelay "0"
Set-ItemProperty "HKCU:\Control Panel\Desktop" WaitToKillAppTimeout "2000"
Set-ItemProperty "HKCU:\Control Panel\Desktop" HungAppTimeout "1000"
Set-ItemProperty "HKCU:\Control Panel\Desktop" AutoEndTasks "1"
Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" String
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" String
# Mouse sin aceleracion (mejor punteria/camara en los juegos)
Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" String
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" String
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" String

# ---------------------------------------------------------------------
Step "Apps en segundo plano, Game Bar/DVR, anuncios y sugerencias: APAGADOS"
# ---------------------------------------------------------------------
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-Reg "HKCU:\Software\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0
Set-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0
Set-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
foreach ($k in "SubscribedContent-338388Enabled","SubscribedContent-338389Enabled","SubscribedContent-353694Enabled","SubscribedContent-353696Enabled","SubscribedContent-338393Enabled","SilentInstalledAppsEnabled","SystemPaneSuggestionsEnabled","SoftLandingEnabled","OemPreInstalledAppsEnabled","PreInstalledAppsEnabled") { Set-Reg $cdm $k 0 }
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" 1

# ---------------------------------------------------------------------
Step "Telemetria, Cortana, busqueda web, SmartScreen, reporte de errores: APAGADOS"
# ---------------------------------------------------------------------
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
# Edge: sin arranque ni procesos en segundo plano
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0

# ---------------------------------------------------------------------
Step "Windows Update: APAGADO"
# ---------------------------------------------------------------------
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "DoNotConnectToWindowsUpdateInternetLocations" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" "AutoDownload" 2

# ---------------------------------------------------------------------
Step "Servicios innecesarios: DETENIDOS Y DESHABILITADOS"
# ---------------------------------------------------------------------
$svc = @(
 "SysMain","WSearch","DiagTrack","dmwappushservice","MapsBroker","WerSvc","Fax",
 "XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","RetailDemo","lfsvc",
 "PcaSvc","TabletInputService","WbioSrvc","wisvc","PhoneSvc","icssvc","SEMgrSvc",
 "WalletService","SCardSvr","ScDeviceEnum","stisvc","DoSvc","wuauserv","UsoSvc",
 "edgeupdate","edgeupdatem","MicrosoftEdgeElevationService","DusmSvc","CDPSvc",
 "diagnosticshub.standardcollector.service","DPS","WdiServiceHost","WdiSystemHost",
 "AJRouter","ALG","CscService","SessionEnv","TermService","UmRdpService",
 "RemoteRegistry","RemoteAccess","SharedAccess","SNMPTRAP","TrkWks","WMPNetworkSvc",
 "Netlogon","NetTcpPortSharing","WpcMonSvc","SmsRouter","PrintNotify","MessagingService"
)
foreach ($s in $svc) {
    Stop-Service $s -Force
    Set-Service $s -StartupType Disabled
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$s" -Name Start -Value 4
}
# Servicios por usuario (plantillas)
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | Where-Object { $_.PSChildName -match '^(OneSyncSvc|CDPUserSvc|PimIndexMaintenanceSvc|UnistoreSvc|UserDataSvc|MessagingService|BcastDVRUserService)' } | ForEach-Object { Set-ItemProperty $_.PSPath -Name Start -Value 4 }
Write-Host "   (Se dejan activos: red, audio, video, Spooler/impresion, Bluetooth, Store)"

# ---------------------------------------------------------------------
Step "Tareas programadas de terceros y de telemetria: DESHABILITADAS"
# ---------------------------------------------------------------------
Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.State -ne 'Disabled' } | ForEach-Object { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath | Out-Null }
$ms = @(
 "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
 "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
 "\Microsoft\Windows\Application Experience\StartupAppTask",
 "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
 "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
 "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
 "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
 "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
 "\Microsoft\Windows\Feedback\Siuf\DmClient",
 "\Microsoft\Windows\Maps\MapsUpdateTask",
 "\Microsoft\Windows\Defrag\ScheduledDefrag",
 "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
 "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
)
foreach ($t in $ms) { Disable-ScheduledTask -TaskPath (Split-Path $t) -TaskName (Split-Path $t -Leaf) | Out-Null }

# ---------------------------------------------------------------------
Step "Programas de inicio: ELIMINADOS (se respalda la lista en el Escritorio)"
# ---------------------------------------------------------------------
$keep = 'Realtek|RTHD|Audio|Sound|Nahimic|Waves'
$bk = "$env:USERPROFILE\Desktop\inicio-respaldo.txt"
"Entradas de inicio eliminadas $(Get-Date)" | Out-File $bk
foreach ($rk in "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run") {
    $p = Get-ItemProperty $rk
    if ($p) {
        $p.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -notmatch $keep } | ForEach-Object {
            "$rk | $($_.Name) = $($_.Value)" | Out-File $bk -Append
            Remove-ItemProperty $rk -Name $_.Name
        }
    }
}

# ---------------------------------------------------------------------
Step "OneDrive: DESINSTALADO"
# ---------------------------------------------------------------------
taskkill /f /im OneDrive.exe | Out-Null
foreach ($f in "$env:SystemRoot\SysWOW64\OneDriveSetup.exe","$env:SystemRoot\System32\OneDriveSetup.exe") { if (Test-Path $f) { & $f /uninstall } }
Start-Sleep 5
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue   # solo si esta vacia/sin uso
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force
Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force

# ---------------------------------------------------------------------
Step "Apps de Windows (bloatware): DESINSTALADAS (se conserva Store, Calculadora, Fotos, codecs)"
# ---------------------------------------------------------------------
$keepApps = 'Store|Calculator|Photos|DesktopAppInstaller|VCLibs|NET\.Native|UI\.Xaml|SecHealthUI|WindowsTerminal|Notepad|HEVC|WebP|VP9|HEIF'
Get-AppxPackage -AllUsers | Where-Object { -not $_.NonRemovable -and -not $_.IsFramework -and $_.Name -notmatch $keepApps } | ForEach-Object {
    Write-Host "   quitando $($_.Name)"
    Remove-AppxPackage -Package $_.PackageFullName -AllUsers
}
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -notmatch $keepApps } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName | Out-Null }

# ---------------------------------------------------------------------
Step "Defender: DESACTIVADO (si no se puede, desactiva a mano 'Proteccion contra alteraciones')"
# ---------------------------------------------------------------------
if ((Get-MpComputerStatus).IsTamperProtected) {
    Write-Host "   La PROTECCION CONTRA ALTERACIONES esta activa y bloquea el cambio." -ForegroundColor Yellow
    Write-Host "   Abre: Seguridad de Windows > Proteccion antivirus y contra amenazas >" -ForegroundColor Yellow
    Write-Host "         Administrar configuracion > desactiva 'Proteccion contra alteraciones'." -ForegroundColor Yellow
    Read-Host "   Cuando la desactives, pulsa ENTER para continuar"
}
Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableIOAVProtection $true -DisableScriptScanning $true -DisableArchiveScanning $true -MAPSReporting 0 -SubmitSamplesConsent 2 -EnableNetworkProtection Disabled -PUAProtection 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiVirus" 1
$rtp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
foreach ($k in "DisableRealtimeMonitoring","DisableBehaviorMonitoring","DisableOnAccessProtection","DisableScanOnRealtimeEnable","DisableIOAVProtection") { Set-Reg $rtp $k 1 }
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpynetReporting" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" 2
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" | Disable-ScheduledTask | Out-Null
Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SecurityHealth"
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\SecurityHealthService" -Name Start -Value 4
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\wscsvc" -Name Start -Value 4

# ---------------------------------------------------------------------
Step "Memoria virtual fija en C: (SSD) y ajustes de memoria"
# ---------------------------------------------------------------------
$ramMB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
if ($ramMB -le 4500) { $ini = 4096; $max = 6144 } else { $ini = $ramMB; $max = $ramMB + 2048 }
$cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$cs.AutomaticManagedPagefile = $false
$cs.Put() | Out-Null
Get-WmiObject Win32_PageFileSetting | ForEach-Object { $_.Delete() }
Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{ Name = "C:\pagefile.sys"; InitialSize = $ini; MaximumSize = $max } | Out-Null
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0

# ---------------------------------------------------------------------
Step "Prioridad de CPU, tiempos del sistema y disco"
# ---------------------------------------------------------------------
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" String
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" String
bcdedit /set disabledynamictick yes | Out-Null
bcdedit /deletevalue useplatformclock | Out-Null
fsutil behavior set disablelastaccess 1 | Out-Null
fsutil behavior set disabledeletenotify 0 | Out-Null    # TRIM activo

# ---------------------------------------------------------------------
Step "Juegos: buscar gta_sa.exe y speed.exe, prioridad alta + sin optimizaciones de pantalla completa + admin"
# ---------------------------------------------------------------------
$found = @()
foreach ($d in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' -and (Test-Path $_.Root) })) {
    $tops = Get-ChildItem $d.Root -Directory -Force | Where-Object { $_.Name -notmatch '^(Windows|\$Recycle\.Bin|System Volume Information|ProgramData|Recovery)$' }
    foreach ($t in $tops) { $found += Get-ChildItem $t.FullName -Recurse -File -Include gta_sa.exe,speed.exe -ErrorAction SilentlyContinue }
}
foreach ($f in $found) {
    Write-Host "   juego encontrado: $($f.FullName)"
    Set-Reg "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" $f.FullName "~ RUNASADMIN DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" String
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" $f.FullName "~ RUNASADMIN DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" String
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($f.Name)\PerfOptions" "CpuPriorityClass" 3   # Alta
}
if (-not $found) { Write-Host "   No encontre los juegos; se omite (puedes volver a correr el script luego)." -ForegroundColor Yellow }

# ---------------------------------------------------------------------
Step "DirectX 9 (necesario para NFS MW 2005 y GTA SA)"
# ---------------------------------------------------------------------
$dx = "$env:TEMP\dxwebsetup.exe"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile $dx -UseBasicParsing
    Start-Process $dx -ArgumentList "/Q" -Wait
    Write-Host "   DirectX instalado."
} catch { Write-Host "   No se pudo descargar DirectX (sin internet?). Instala 'DirectX End-User Runtime Web Installer' a mano." -ForegroundColor Yellow }

# ---------------------------------------------------------------------
Step "Limpieza profunda de disco"
# ---------------------------------------------------------------------
Remove-Item "$env:TEMP\*" -Recurse -Force
Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force
Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force
Remove-Item "$env:SystemRoot\Logs\CBS\*" -Force
Remove-Item "$env:ProgramData\Microsoft\Windows\WER\*" -Recurse -Force
Clear-RecycleBin -Force
dism /online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
Optimize-Volume -DriveLetter C -ReTrim

# ---------------------------------------------------------------------
Step "Reiniciar explorer para aplicar efectos"
# ---------------------------------------------------------------------
Stop-Process -Name explorer -Force
Start-Sleep 2
if (-not (Get-Process explorer)) { Start-Process explorer }

Write-Host ""
Write-Host "=================== LISTO ===================" -ForegroundColor Green
Write-Host "Log: Escritorio\optimizacion-log.txt  |  Inicio respaldado: Escritorio\inicio-respaldo.txt"
Write-Host "Para deshacer todo: Restaurar sistema > punto 'Antes de optimizar para juegos'."
try { Stop-Transcript | Out-Null } catch {}
$r = Read-Host "Es NECESARIO reiniciar. Reiniciar ahora? (S/N)"
if ($r -match '^[sSyY]') { Restart-Computer -Force }

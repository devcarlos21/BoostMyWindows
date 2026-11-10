#Requires -Version 5.1
<#
    BoostMyWindows - optimizador para Windows 10 y 11
    Repo: https://github.com/devcarlos21/BoostMyWindows

    Modos (cada uno incluye los anteriores):
      Easy     Ajustes seguros y reversibles. No quita proteccion ni apps.
      Medium   + apaga servicios de bajo impacto, quita OneDrive y bloatware.
      Extreme  + apaga servicios con perdida de funciones, tweaks de juego.
      YOLO     + apaga Windows Update y Defender. Sin red de seguridad.

    Uso:
      .\BoostMyWindows.ps1                 menu interactivo
      .\BoostMyWindows.ps1 -Mode Medium    aplica un modo
      .\BoostMyWindows.ps1 -Mode Custom    menu con casillas (elige modulo a modulo)
      .\BoostMyWindows.ps1 -Mode YOLO -Force   sin preguntas (automatico)
#>
param(
    [ValidateSet('Easy','Medium','Extreme','YOLO','Custom','Menu')]
    [string]$Mode = 'Menu',
    [switch]$Force
)

# --- Auto-elevar a administrador ---
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Mode $Mode"
    if ($Force) { $a += " -Force" }
    Start-Process powershell -Verb RunAs -ArgumentList $a
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
try { Start-Transcript -Path "$env:USERPROFILE\Desktop\BoostMyWindows-log.txt" -Force | Out-Null } catch {}

# --- Deteccion de version ---
$build = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$Win11 = $build -ge 22000
$osName = if ($Win11) { "Windows 11" } else { "Windows 10" }

$levels = [ordered]@{ Easy = 1; Medium = 2; Extreme = 3; YOLO = 4 }

# --- Helpers ---
function Set-Reg($p, $n, $v, $t = 'DWord') {
    try {
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name $n -Value $v -PropertyType $t -Force | Out-Null
    } catch {}
}
function Disable-Services($list) {
    foreach ($s in $list) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
        Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$s" -Name Start -Value 4 -ErrorAction SilentlyContinue
    }
}

# =====================================================================
#  CATALOGO DE MODULOS. Cada uno tiene un nivel (Tier) y una accion.
#  Un modo ejecuta todos los modulos de su nivel y los inferiores.
# =====================================================================
$tweaks = @(
  @{ Id=1; Name='Punto de restauracion'; Tier='Easy'; Warn=''; Do={
      Enable-ComputerRestore -Drive "C:\"
      Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" "SystemRestorePointCreationFrequency" 0
      Checkpoint-Computer -Description "Antes de BoostMyWindows" -RestorePointType MODIFY_SETTINGS
  }}
  @{ Id=2; Name='Plan de energia maximo rendimiento'; Tier='Easy'; Warn=''; Do={
      $out = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-String)
      if ($out -match '([0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})') { $g = $Matches[1] } else { $g = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
      powercfg -setactive $g
      powercfg -setacvalueindex $g 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
      powercfg -setacvalueindex $g 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
      powercfg -change -disk-timeout-ac 0
      powercfg -change -standby-timeout-ac 0
      powercfg -setactive $g
      powercfg -h off
      Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
  }}
  @{ Id=3; Name='Efectos visuales al minimo y mouse sin aceleracion'; Tier='Easy'; Warn=''; Do={
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
      Set-ItemProperty "HKCU:\Control Panel\Desktop" UserPreferencesMask ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
      Set-ItemProperty "HKCU:\Control Panel\Desktop" MenuShowDelay "0"
      Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" String
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
      Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" String
      Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" String
      Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" String
  }}
  @{ Id=4; Name='Apps en segundo plano, Game Bar y anuncios'; Tier='Easy'; Warn=''; Do={
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
      Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
      $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
      foreach ($k in "SubscribedContent-338388Enabled","SubscribedContent-338389Enabled","SubscribedContent-353694Enabled","SubscribedContent-353696Enabled","SilentInstalledAppsEnabled","SystemPaneSuggestionsEnabled","SoftLandingEnabled","PreInstalledAppsEnabled") { Set-Reg $cdm $k 0 }
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
  }}
  @{ Id=5; Name='Telemetria, Cortana y reporte de errores'; Tier='Easy'; Warn=''; Do={
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
      Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
  }}
  @{ Id=6; Name='Ajustes de interfaz de Windows 11'; Tier='Easy'; Warn='Solo aplica en Windows 11'; Do={
      if (-not $Win11) { return }
      # Menu contextual clasico (clic derecho completo como en Win10)
      New-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
      Set-ItemProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(Default)" ""
      # Quitar boton de Widgets y de Chat de la barra
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
      Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
      # Sin recomendaciones ni anuncios en el menu Inicio
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" 1
  }}
  @{ Id=7; Name='Limpieza de temporales y TRIM del SSD'; Tier='Easy'; Warn=''; Do={
      Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
      Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
      Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
      Clear-RecycleBin -Force -ErrorAction SilentlyContinue
      Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
  }}

  @{ Id=20; Name='Apagar servicios de bajo impacto'; Tier='Medium'; Warn='Se pierden: funciones Xbox, mapas, fax, sincronizacion de telefono'; Do={
      Disable-Services @("SysMain","DiagTrack","dmwappushservice","MapsBroker","Fax","XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","RetailDemo","WerSvc","WMPNetworkSvc","PhoneSvc","WalletService","SmsRouter","MessagingService","DoSvc","diagnosticshub.standardcollector.service")
      Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | Where-Object { $_.PSChildName -match '^(OneSyncSvc|PimIndexMaintenanceSvc|UnistoreSvc|UserDataSvc|BcastDVRUserService)' } | ForEach-Object { Set-ItemProperty $_.PSPath -Name Start -Value 4 -ErrorAction SilentlyContinue }
  }}
  @{ Id=21; Name='Apagar tareas programadas de telemetria'; Tier='Medium'; Warn=''; Do={
      $ms = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\Feedback\Siuf\DmClient"
      )
      foreach ($t in $ms) { Disable-ScheduledTask -TaskPath (Split-Path $t) -TaskName (Split-Path $t -Leaf) -ErrorAction SilentlyContinue | Out-Null }
  }}
  @{ Id=22; Name='Desinstalar OneDrive'; Tier='Medium'; Warn='Deja de sincronizar la carpeta OneDrive'; Do={
      taskkill /f /im OneDrive.exe 2>$null | Out-Null
      foreach ($f in "$env:SystemRoot\SysWOW64\OneDriveSetup.exe","$env:SystemRoot\System32\OneDriveSetup.exe") { if (Test-Path $f) { & $f /uninstall } }
      Start-Sleep 3
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
  }}
  @{ Id=23; Name='Quitar apps preinstaladas (bloatware)'; Tier='Medium'; Warn='Quita apps de Windows; conserva Store, Calculadora, Fotos, codecs'; Do={
      $keep = 'Store|Calculator|Photos|DesktopAppInstaller|VCLibs|NET\.Native|UI\.Xaml|SecHealthUI|WindowsTerminal|Notepad|HEVC|WebP|VP9|HEIF|Paint'
      Get-AppxPackage -AllUsers | Where-Object { -not $_.NonRemovable -and -not $_.IsFramework -and $_.Name -notmatch $keep } | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }
      Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -notmatch $keep } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
  }}
  @{ Id=24; Name='Archivo de paginacion fijo en el SSD'; Tier='Medium'; Warn=''; Do={
      $ramMB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
      if ($ramMB -le 4500) { $ini = 4096; $max = 6144 } else { $ini = $ramMB; $max = $ramMB + 2048 }
      $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
      $cs.AutomaticManagedPagefile = $false; $cs.Put() | Out-Null
      Get-WmiObject Win32_PageFileSetting | ForEach-Object { $_.Delete() }
      Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{ Name = "C:\pagefile.sys"; InitialSize = $ini; MaximumSize = $max } | Out-Null
  }}

  @{ Id=40; Name='Apagar servicios con perdida de funciones'; Tier='Extreme'; Warn='APAGA: busqueda de Windows, huella/Hello, ubicacion, escritorio remoto'; Do={
      Disable-Services @("WSearch","WbioSrvc","lfsvc","TabletInputService","SCardSvr","ScDeviceEnum","PcaSvc","TrkWks","RemoteRegistry","RemoteAccess","SharedAccess","SessionEnv","TermService","UmRdpService","AJRouter","ALG","RetailDemo","icssvc","WpcMonSvc")
  }}
  @{ Id=41; Name='Quitar programas de inicio'; Tier='Extreme'; Warn='Quita todo el autoarranque salvo audio; respaldo en el Escritorio'; Do={
      $keepRun = 'Realtek|RTHD|Audio|Sound|Nahimic|Waves'
      $bk = "$env:USERPROFILE\Desktop\BoostMyWindows-inicio-respaldo.txt"
      "Entradas de inicio eliminadas $(Get-Date)" | Out-File $bk
      foreach ($rk in "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run") {
          $p = Get-ItemProperty $rk -ErrorAction SilentlyContinue
          if ($p) { $p.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -notmatch $keepRun } | ForEach-Object {
              "$rk | $($_.Name) = $($_.Value)" | Out-File $bk -Append
              Remove-ItemProperty $rk -Name $_.Name -ErrorAction SilentlyContinue } }
      }
  }}
  @{ Id=42; Name='Prioridad de CPU y red para juegos'; Tier='Extreme'; Warn=''; Do={
      Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
      Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
      Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295
      $g = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
      Set-Reg $g "GPU Priority" 8; Set-Reg $g "Priority" 6
      Set-Reg $g "Scheduling Category" "High" String; Set-Reg $g "SFIO Priority" "High" String
      Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1
      fsutil behavior set disablelastaccess 1 | Out-Null
  }}
  @{ Id=43; Name='Optimizar juegos detectados (gta_sa, speed.exe)'; Tier='Extreme'; Warn='Busca en todos los discos; puede tardar'; Do={
      $found = @()
      foreach ($d in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' -and (Test-Path $_.Root) })) {
          $tops = Get-ChildItem $d.Root -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(Windows|\$Recycle\.Bin|System Volume Information|ProgramData|Recovery)$' }
          foreach ($t in $tops) { $found += Get-ChildItem $t.FullName -Recurse -File -Include gta_sa.exe,speed.exe -ErrorAction SilentlyContinue }
      }
      foreach ($f in $found) {
          Write-Host "   juego: $($f.FullName)"
          Set-Reg "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" $f.FullName "~ RUNASADMIN DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" String
          Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($f.Name)\PerfOptions" "CpuPriorityClass" 3
      }
      if (-not $found) { Write-Host "   No se encontraron los juegos; se omite." }
  }}

  @{ Id=60; Name='Apagar Windows Update'; Tier='YOLO'; Warn='La PC deja de recibir parches de seguridad'; Do={
      Disable-Services @("wuauserv","UsoSvc","WaaSMedicSvc","BITS")
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 1
  }}
  @{ Id=61; Name='Apagar Microsoft Defender'; Tier='YOLO'; Warn='La PC queda SIN ANTIVIRUS. Solo para equipos de solo juego'; Do={
      if ((Get-MpComputerStatus).IsTamperProtected) {
          Write-Host "   Defender tiene PROTECCION CONTRA ALTERACIONES activa." -ForegroundColor Yellow
          Write-Host "   Microsoft obliga a desactivarla A MANO (ningun script puede)." -ForegroundColor Yellow
          Write-Host "   Abre: Seguridad de Windows > Proteccion antivirus > Administrar" -ForegroundColor Yellow
          Write-Host "         configuracion > apaga 'Proteccion contra alteraciones'." -ForegroundColor Yellow
          Read-Host "   Cuando lo hagas pulsa ENTER (o ENTER para omitir Defender)"
      }
      Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableScriptScanning $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
      Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
      $rtp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
      foreach ($k in "DisableRealtimeMonitoring","DisableBehaviorMonitoring","DisableOnAccessProtection","DisableScanOnRealtimeEnable") { Set-Reg $rtp $k 1 }
  }}
)

# --- Auto-chequeo del catalogo (atrapa errores de autoria) ---
$bad = $tweaks | Where-Object { -not $levels.Contains($_.Tier) }
if ($bad) { Write-Host "ERROR: modulo con nivel invalido: $($bad.Name -join ', ')" -ForegroundColor Red; exit 1 }
if (($tweaks.Id | Sort-Object -Unique).Count -ne $tweaks.Count) { Write-Host "ERROR: hay Ids de modulo duplicados" -ForegroundColor Red; exit 1 }

# =====================================================================
#  SELECCION DE MODO
# =====================================================================
Clear-Host
Write-Host "  ____                  _   __  __       " -ForegroundColor Cyan
Write-Host " | __ )  ___   ___  ___| |_|  \/  |_   _ " -ForegroundColor Cyan
Write-Host " |  _ \ / _ \ / _ \/ __| __| |\/| | | | |" -ForegroundColor Cyan
Write-Host " | |_) | (_) | (_) \__ \ |_| |  | | |_| |" -ForegroundColor Cyan
Write-Host " |____/ \___/ \___/|___/\__|_|  |_|\__, |" -ForegroundColor Cyan
Write-Host "        BoostMyWindows  -  $osName   |___/ " -ForegroundColor Cyan
Write-Host ""

if ($Mode -eq 'Menu') {
    Write-Host " Elige un modo:" -ForegroundColor Green
    Write-Host "   1) Easy     - seguro y reversible, no quita proteccion"
    Write-Host "   2) Medium   - + apaga servicios de bajo impacto, OneDrive, bloatware"
    Write-Host "   3) Extreme  - + busqueda/huella/remoto apagados, tweaks de juego"
    Write-Host "   4) YOLO     - + apaga Update y DEFENDER (sin antivirus)" -ForegroundColor Yellow
    Write-Host "   5) Custom   - elige modulo a modulo con casillas"
    Write-Host ""
    switch (Read-Host " Numero") {
        '1' { $Mode = 'Easy' }; '2' { $Mode = 'Medium' }; '3' { $Mode = 'Extreme' }
        '4' { $Mode = 'YOLO' }; '5' { $Mode = 'Custom' }
        default { Write-Host "Opcion invalida."; exit }
    }
}

if ($Mode -eq 'Custom') {
    $grid = $tweaks | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Modulo = $_.Name; Nivel = $_.Tier; Aviso = $_.Warn } }
    $sel = $grid | Out-GridView -Title "Marca los modulos a aplicar (Ctrl+clic para varios) y pulsa Aceptar" -PassThru
    if (-not $sel) { Write-Host "No seleccionaste nada. Salgo."; exit }
    $run = $tweaks | Where-Object { $_.Id -in $sel.Id }
} else {
    $lvl = $levels[$Mode]
    $run = $tweaks | Where-Object { $levels[$_.Tier] -le $lvl }
}

# =====================================================================
#  CONFIRMACION Y EJECUCION
# =====================================================================
Write-Host ""
Write-Host " Modo: $Mode   Modulos a aplicar: $($run.Count)" -ForegroundColor Green
$warns = $run | Where-Object { $_.Warn }
if ($warns) {
    Write-Host " Avisos:" -ForegroundColor Yellow
    foreach ($w in $warns) { Write-Host "   - $($w.Name): $($w.Warn)" -ForegroundColor Yellow }
}
Write-Host " Se creara un punto de restauracion para poder deshacer todo." -ForegroundColor DarkGray

if (-not $Force) {
    if ((Read-Host "`n Escribe SI para continuar") -ne 'SI') { Write-Host "Cancelado."; exit }
}

$i = 0
foreach ($t in $run) {
    $i++
    Write-Progress -Activity "BoostMyWindows ($Mode)" -Status $t.Name -PercentComplete (($i / $run.Count) * 100)
    Write-Host ("[{0}/{1}] {2}" -f $i, $run.Count, $t.Name) -ForegroundColor Cyan
    try { & $t.Do } catch { Write-Host "   (omitido) $_" -ForegroundColor DarkYellow }
}

Write-Host ""
Write-Host "=================== LISTO ===================" -ForegroundColor Green
Write-Host " Log: Escritorio\BoostMyWindows-log.txt"
Write-Host " Deshacer: Inicio > 'Crear punto de restauracion' > Restaurar sistema"
Write-Host "           > punto 'Antes de BoostMyWindows'."
try { Stop-Transcript | Out-Null } catch {}

if (-not $Force) {
    if ((Read-Host "`n Conviene reiniciar. Reiniciar ahora? (S/N)") -match '^[sSyY]') { Restart-Computer -Force }
}

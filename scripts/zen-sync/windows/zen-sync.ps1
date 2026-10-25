# zen-sync: mantiene la sesión de Zen (pestañas, espacios, essentials, carpetas) igual entre
# equipos a través del NAS. Funciona abras Zen como lo abras: un vigilante en segundo plano
# baja la sesión más nueva mientras Zen está cerrado y la sube cuando Zen se cierra.
# Uso: zen-sync.ps1                          (vigilante; lo arranca la tarea "Zen Sync" al iniciar sesión)
#      zen-sync.ps1 -Accion subir|bajar|estado
param([ValidateSet('vigilar', 'subir', 'bajar', 'estado')][string]$Accion = 'vigilar')

$Sync  = if ($env:ZEN_SYNC_DIR) { $env:ZEN_SYNC_DIR } else { '\\TRUENAS\Emulacion\Development\Tools\zen-sync' }
$State = Join-Path $env:USERPROFILE '.zen-sync'
$HostN = $env:COMPUTERNAME.ToLower()
$Intervalo    = 5     # cada cuánto se mira si Zen está abierto
$ComprobarNas = 10    # cada cuánto se busca una sesión nueva en el NAS con Zen cerrado
$Stale        = 180   # segundos sin latido para dar por cerrado Zen en otro equipo
$Keep         = 5     # versiones que se guardan en el NAS
$Files = @('zen-sessions.jsonlz4', 'sessionstore.jsonlz4', 'sessionstore-backups/recovery.jsonlz4',
           'zen-live-folders.jsonlz4', 'zen-space-routing.jsonlz4', 'zen-themes.json',
           'zen-keyboard-shortcuts.json', 'containers.json', 'chrome')

New-Item -ItemType Directory -Force $State | Out-Null
function Ahora { [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
function Log($m) { Add-Content (Join-Path $State 'zen-sync.log') "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" }
function Aviso($m) {
    Log $m
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $x = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $t = $x.GetElementsByTagName('text')
        $null = $t.Item(0).AppendChild($x.CreateTextNode('Zen'))
        $null = $t.Item(1).AppendChild($x.CreateTextNode($m))
        $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($x))
    } catch { }
}

# Perfil por defecto de Zen según su profiles.ini (vale para cualquier equipo)
function Perfil {
    if ($env:ZEN_PROFILE) { return $env:ZEN_PROFILE }
    $d = Join-Path $env:APPDATA 'zen'; $ini = Join-Path $d 'profiles.ini'
    if (-not (Test-Path $ini)) { return $null }
    $sec = ''; $inst = $null; $path = $null; $def = $false; $prof = $null
    foreach ($l in Get-Content $ini) {
        if ($l -match '^\[(.+)\]') {
            if (-not $prof -and $def -and $path) { $prof = $path }
            $sec = $Matches[1]; $path = $null; $def = $false; continue
        }
        if ($l -match '^Path=(.+)$') { $path = $Matches[1] }
        elseif ($l -match '^Default=(.+)$') {
            if ($sec -like 'Install*') { if (-not $inst) { $inst = $Matches[1] } }
            elseif ($Matches[1] -eq '1') { $def = $true }
        }
    }
    if (-not $prof -and $def -and $path) { $prof = $path }
    $rel = if ($inst) { $inst } else { $prof }
    if (-not $rel) { return $null }
    return Join-Path $d ($rel -replace '/', '\')
}
$Prof = Perfil

function ZenAbierto { [bool](Get-Process zen -ErrorAction SilentlyContinue) }
function NasOk {
    try {
        if (-not (Test-Path -LiteralPath (Split-Path $Sync -Parent) -ErrorAction Stop)) { return $false }
        New-Item -ItemType Directory -Force $Sync | Out-Null
        return $true
    } catch { return $false }
}
function LeerNum($f) { if (Test-Path $f) { [long](Get-Content $f -Raw).Trim() } else { 0 } }
function SeqLocal { LeerNum (Join-Path $State 'seq') }
function Marca { LeerNum (Join-Path $State 'marca') }
function MTime {
    $f = Join-Path $Prof 'zen-sessions.jsonlz4'
    if (Test-Path $f) { [DateTimeOffset]::new((Get-Item $f).LastWriteTimeUtc).ToUnixTimeSeconds() } else { 0 }
}
function Guardar($nombre, $valor) { Set-Content (Join-Path $State $nombre) $valor -Encoding ascii -NoNewline }

function LeerMeta {
    $f = Join-Path $Sync 'meta.txt'
    if (Test-Path $f) {
        $p = (Get-Content $f -Raw).Trim() -split '\s+'
        if ($p.Count -ge 3) { return @{ Seq = [long]$p[0]; Host = $p[1]; Time = [long]$p[2] } }
    }
    return @{ Seq = 0; Host = ''; Time = 0 }
}
function LeerCandado {
    $f = Join-Path $Sync 'lock.txt'
    if (Test-Path $f) {
        $p = (Get-Content $f -Raw).Trim() -split '\s+'
        if ($p.Count -ge 2) { return @{ Host = $p[0]; Time = [long]$p[1] } }
    }
    return @{ Host = ''; Time = 0 }
}
function EscribirCandado {
    $t = Join-Path $Sync "lock.txt.$HostN"
    Set-Content $t "$HostN $(Ahora)" -Encoding ascii -NoNewline
    Move-Item $t (Join-Path $Sync 'lock.txt') -Force
}
function LiberarCandado {
    if ((LeerCandado).Host -eq $HostN) { Remove-Item (Join-Path $Sync 'lock.txt') -Force -ErrorAction SilentlyContinue }
}

function Existentes { $Files | Where-Object { Test-Path -LiteralPath (Join-Path $Prof $_) } }

function RespaldarLocal {
    $dir = Join-Path $State 'backup'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $ex = @(Existentes)
    & tar.exe -czf (Join-Path $dir "$(Ahora).tar.gz") -C $Prof @ex
    Get-ChildItem $dir -Filter *.tar.gz | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 | Remove-Item -Force
}

function BajarSesion {
    $r = LeerMeta; $tar = Join-Path $Sync 'session.tar'
    if ($r.Seq -le 0 -or -not (Test-Path $tar)) { return }
    & tar.exe -tf $tar | Out-Null
    if ($LASTEXITCODE -ne 0) { Log 'la sesión del NAS está dañada; no la bajo'; return }
    RespaldarLocal
    if (ZenAbierto) { return }
    $bk = Join-Path $Prof 'sessionstore-backups'
    Remove-Item (Join-Path $bk 'recovery.jsonlz4'), (Join-Path $bk 'recovery.baklz4'), (Join-Path $bk 'previous.jsonlz4') -Force -ErrorAction SilentlyContinue
    & tar.exe -xf $tar -C $Prof
    if ($LASTEXITCODE -ne 0) { Aviso 'Error al extraer la sesión del NAS.'; return }
    Guardar 'seq' $r.Seq; Guardar 'marca' (MTime)
    Log "bajada versión $($r.Seq) de $($r.Host)"; Aviso "Sesión traída de $($r.Host)"
}

function SubirSesion {
    $ses = Join-Path $Prof 'zen-sessions.jsonlz4'
    if (-not (Test-Path $ses) -or (Get-Item $ses).Length -lt 500) { Log 'sesión vacía, no la subo'; return $false }
    $m = MTime
    $tmp = Join-Path $Sync "session.tar.$HostN.tmp"
    $ex = @(Existentes)
    & tar.exe -cf $tmp -C $Prof @ex
    if ($LASTEXITCODE -ne 0) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue; Aviso 'No pude empaquetar la sesión.'; return $false }
    $r = LeerMeta
    $nueva = [Math]::Max($r.Seq, (SeqLocal)) + 1
    $h = Join-Path $Sync 'history'
    New-Item -ItemType Directory -Force $h | Out-Null
    $cur = Join-Path $Sync 'session.tar'
    if (Test-Path $cur) { Copy-Item $cur (Join-Path $h "$($r.Seq)-$(if ($r.Host) { $r.Host } else { 'x' }).tar") -Force }
    Move-Item $tmp $cur -Force
    $mt = Join-Path $Sync "meta.txt.$HostN"
    Set-Content $mt "$nueva $HostN $(Ahora)" -Encoding ascii -NoNewline
    Move-Item $mt (Join-Path $Sync 'meta.txt') -Force
    Guardar 'seq' $nueva; Guardar 'marca' $m
    Get-ChildItem $h -Filter *.tar | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep | Remove-Item -Force
    Log "subida versión $nueva"; Aviso 'Sesión guardada en el NAS'
    return $true
}

# Con Zen cerrado: baja la sesión del NAS si es más nueva, o sube la local si cambió sin subirse
function SincronizarInactivo {
    if (-not (NasOk)) { return }
    $r = LeerMeta; $m = MTime; $mk = Marca
    if ($r.Seq -gt (SeqLocal)) {
        if ($m -ne $mk -and $m -gt $r.Time) { Log "la sesión local es más nueva que la del NAS ($($r.Host))"; [void](SubirSesion) }
        else { BajarSesion }
    } elseif ($m -ne $mk -and $m -gt 0) { [void](SubirSesion) }
}

function Vigilar {
    $mtx = New-Object Threading.Mutex($false, 'Local\ZenSyncVigilar')
    if (-not $mtx.WaitOne(0)) { return }
    Log "vigilante iniciado en $HostN (perfil: $Prof)"
    $antes = $false; $ultNas = 0; $ultLat = 0
    while ($true) {
        try {
            $abierto = ZenAbierto
            if ($abierto -and -not $antes) {
                Log 'Zen abierto'
                if (NasOk) {
                    $c = LeerCandado
                    if ($c.Host -and $c.Host -ne $HostN -and ((Ahora) - $c.Time) -lt $Stale) {
                        Aviso "Zen también está abierto en '$($c.Host)'. Se guardará la sesión del último que cierre."
                    }
                    EscribirCandado
                }
                $ultLat = Ahora
            } elseif ($abierto) {
                if (((Ahora) - $ultLat) -ge 60) { if (NasOk) { EscribirCandado }; $ultLat = Ahora }
            } elseif ($antes) {
                Log 'Zen cerrado'
                Start-Sleep 2
                if (NasOk) { [void](SubirSesion); LiberarCandado } else { Aviso 'NAS no disponible: la sesión se subirá cuando vuelva.' }
                $ultNas = Ahora
            } elseif (((Ahora) - $ultNas) -ge $ComprobarNas) {
                SincronizarInactivo; $ultNas = Ahora
            }
            $antes = $abierto
        } catch { Log "error: $($_.Exception.Message)" }
        Start-Sleep $Intervalo
    }
}

if (-not $Prof -or -not (Test-Path $Prof)) { Log 'no encuentro el perfil de Zen'; 'No encuentro el perfil de Zen.'; exit 1 }

switch ($Accion) {
    'vigilar' { Vigilar }
    'estado' {
        $r = LeerMeta; $c = LeerCandado
        "equipo: $HostN | perfil: $Prof"
        "local: versión $(SeqLocal), cambios sin subir: $(if ((MTime) -ne (Marca)) { 'sí' } else { 'no' })"
        "NAS:   versión $($r.Seq) de $($r.Host)"
        "candado: $(if ($c.Host) { $c.Host } else { 'libre' })"
    }
    default {
        if (ZenAbierto) { 'Cierra Zen primero.'; exit 1 }
        if (-not (NasOk)) { 'NAS no disponible.'; exit 1 }
        if ($Accion -eq 'bajar') { BajarSesion } else { [void](SubirSesion) }
    }
}

param(
  [Parameter(Mandatory=$true)][string]$DotnetPath,
  [Parameter(Mandatory=$true)][string]$IsccPath
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workRoot = Join-Path $repoRoot ('installer-work/' + [Guid]::NewGuid().ToString('N'))
$payload = Join-Path $workRoot 'payload'
New-Item -ItemType Directory -Path $payload -Force | Out-Null
$projects = @('MonitorAndControl.csproj','Watchdog/SystemHelperWatchdog.csproj','PopupHost/PopupHost.csproj','UpdateAgent/UpdateAgent.csproj')
Push-Location $repoRoot
try {
  foreach ($project in $projects) {
    $out = Join-Path $workRoot ([IO.Path]::GetFileNameWithoutExtension($project))
    & $DotnetPath publish $project -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -o $out
    if ($LASTEXITCODE -ne 0) { throw "Publish failed: $project" }
    foreach ($file in Get-ChildItem -LiteralPath $out -Recurse -File) {
      $relative = $file.FullName.Substring($out.Length).TrimStart('\')
      $dest = Join-Path $payload $relative
      if (Test-Path -LiteralPath $dest) {
        if ((Get-FileHash -LiteralPath $dest).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) { throw "Conflicting publish asset: $relative" }
      } else {
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($dest)) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $dest
      }
    }
  }
  $configPath = Join-Path $payload 'appsettings.json'
  $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
  $config.DashboardPort = 5000
  $config.EnableRemoteDashboard = $false
  $config.DashboardBindAddress = '127.0.0.1'
  $config.DefaultLimits = @()
  $config.Schedule = @()
  [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 15), [Text.UTF8Encoding]::new($false))
  [xml]$projectXml = Get-Content (Join-Path $repoRoot 'MonitorAndControl.csproj')
  $version = [string]$projectXml.Project.PropertyGroup.Version
  & $IsccPath "/DPayloadDir=$payload" "/DAppVersion=$version" (Join-Path $PSScriptRoot 'MonitorAndControl.iss')
  if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
  $artifact = Join-Path $repoRoot "dist/MonitorAndControl-Setup-$version-x64.exe"
  $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
  [IO.File]::WriteAllText("$artifact.sha256", "$hash  $([IO.Path]::GetFileName($artifact))"+[Environment]::NewLine)
  Write-Output $artifact
} finally { Pop-Location }

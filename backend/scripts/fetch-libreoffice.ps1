<#
.SYNOPSIS
  Baixa o instalador oficial do LibreOffice e extrai os arquivos para
  backend/vendor/libreoffice/, sem instalar (sem registro do Windows, sem
  entrada no Menu Iniciar).

.DESCRIPTION
  backend/vendor/libreoffice/ nunca e commitado (~1,5GB extraido) -- este
  script e o jeito de reconstrui-lo em qualquer checkout novo ou maquina de
  build. E a mesma extracao administrativa do MSI (msiexec /a) que qualquer
  instalador corporativo usa para gerar uma copia "portatil"; o PDF que ela
  gera e byte a byte identico ao de uma instalacao normal (verificado).

  A copia gerada e usada pelo backend/src/services/libreoffice.js como
  prioridade sobre um LibreOffice instalado no sistema -- veja
  BUNDLED_SOFFICE nesse arquivo.

.PARAMETER Version
  Versao do LibreOffice a baixar. Default: a mais recente testada com o
  DiaKit (26.2.5). Trocar a versao aqui NAO foi validado -- teste uma
  conversao real antes de confiar no resultado.

.EXAMPLE
  .\fetch-libreoffice.ps1
#>
param(
  [string]$Version = '26.2.5'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$vendorDir = Join-Path $repoRoot 'vendor\libreoffice'
$msiUrl = "https://download.documentfoundation.org/libreoffice/stable/$Version/win/x86_64/LibreOffice_${Version}_Win_x86-64.msi"
$msiPath = Join-Path $env:TEMP "LibreOffice_$Version.msi"

if (Test-Path (Join-Path $vendorDir 'program\soffice.exe')) {
  Write-Output "Ja existe uma copia em $vendorDir -- apague a pasta antes de rodar de novo, se quiser refazer."
  exit 0
}

Write-Output "Baixando $msiUrl (~370MB)..."
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

Write-Output "Extraindo (instalacao administrativa, nada e registrado no sistema)..."
$tempExtract = Join-Path $env:TEMP "lo-extract-$Version"
$proc = Start-Process msiexec.exe -ArgumentList @(
  '/a', "`"$msiPath`"",
  '/qb',
  "TARGETDIR=`"$tempExtract`""
) -PassThru -Wait

if ($proc.ExitCode -ne 0) {
  throw "msiexec falhou com codigo $($proc.ExitCode)"
}

Write-Output "Movendo para $vendorDir..."
New-Item -ItemType Directory -Force -Path (Split-Path $vendorDir) | Out-Null
robocopy $tempExtract $vendorDir /E /MOVE /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) {
  throw "robocopy falhou com codigo $LASTEXITCODE"
}

Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

if (Test-Path (Join-Path $vendorDir 'program\soffice.exe')) {
  Write-Output "OK: $vendorDir\program\soffice.exe"
} else {
  throw 'soffice.exe nao apareceu no destino esperado -- extracao falhou.'
}

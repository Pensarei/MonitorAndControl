# Roteiro de configuração do PC controlado

Revisão: 25/10/2026. Fork: [Pensarei/MonitorAndControl](https://github.com/Pensarei/MonitorAndControl).
Execução manual por etapas; não colar todos os blocos de uma vez. Este documento não aplica configurações automaticamente.
Consolida comandos usados na conversa, com verificações para reutilização.

## 1. Cenário e limites

Windows identificado: Windows 10 Pro 22H2, build 19045, 64 bits.
Administrador separado: AdminControle. Conta local controlada: user.
Senha Windows, senha do painel e conta NextDNS são credenciais distintas; não salvá-las no documento ou Git.

- Conta padrão + UAC exige credenciais para operações privilegiadas, mas não impede todo software. Portáteis, instaladores por usuário e alguns apps da Store podem funcionar sem elevação.
- Impedir qualquer app não aprovado exige política adicional de controle de aplicativos, ainda não configurada.
- NextDNS é global neste roteiro: afeta todas as contas, inclusive AdminControle.
- Perfil NextDNS nomeado por PC não é perfil por conta Windows.
- DNS não inspeciona cada imagem/mensagem; VPNs e resolvedores próprios precisam de tratamento adicional.
- Monitor & Control atual limita apps/grupos. O limite de tela por conta possui implementação experimental 1.7.0; ver TEMPO_PC_NEW.md antes de ativar.

## 2. Preparação e acesso remoto

Usar Windows PowerShell 64 bits como administrador, no PC controlado.
Manter acesso físico e testar uma conta administrativa antes de retirar privilégios da antiga.
Assistência Rápida: Win+Ctrl+Q nos dois PCs; gerar código no PC do responsável e autorizar no controlado.
A assistência exige conta Microsoft do assistente. A conversa/Enviar instrução foi utilizada para transferir comandos; Ctrl+C/Ctrl+V entre PCs não funcionou no cenário observado.
Prompts UAC podem exigir ação física. Não desativar a área de trabalho segura para contornar isso.
Sair da sessão ou reiniciar pode encerrar a assistência; combinar reconexão.

Identificar Windows, conta atual e demais contas:

~~~powershell
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture
whoami
Get-LocalUser | Select-Object Name, Enabled, PrincipalSource, SID
Get-LocalGroupMember -SID 'S-1-5-32-544'
~~~

Usar Name, não nome de exibição, nos comandos. O SID identifica a conta mesmo após renomear.

## 3. Criar o administrador

Executar na conta que atualmente é administradora, em PowerShell elevado.
Não modifica uma conta já existente.

~~~powershell
$ErrorActionPreference = 'Stop'
$nomeAdmin = 'AdminControle'
$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Abra o PowerShell como administrador.'
}
if (Get-LocalUser -Name $nomeAdmin -ErrorAction SilentlyContinue) {
    throw 'AdminControle já existe. Verifique e teste essa conta antes de continuar.'
}
$senhaAdmin = Read-Host 'Senha do novo administrador' -AsSecureString
$novoAdmin = New-LocalUser -Name $nomeAdmin -Password $senhaAdmin
Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $novoAdmin
Get-LocalGroupMember -SID 'S-1-5-32-544'
~~~

SAIR da conta antiga, entrar em AdminControle com a senha criada e testar abertura de PowerShell elevado.
Somente depois desse teste avançar. Uma entrada na lista não prova que a senha funciona.

## 4. Tornar user um usuário padrão

Executar conectado em AdminControle, com PowerShell elevado.
Trocar nomeControlado se o PC usa outro nome.
Este bloco mantém a senha atual da conta controlada.

~~~powershell
$ErrorActionPreference = 'Stop'
$nomeControlado = 'user'
$nomeAdmin = 'AdminControle'
$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Abra o PowerShell como administrador.'
}
$usuario = Get-LocalUser -Name $nomeControlado
$admin = Get-LocalUser -Name $nomeAdmin
if (-not $usuario.Enabled -or -not $admin.Enabled) {
    throw 'As duas contas precisam estar habilitadas.'
}
if ($usuario.SID.Value -eq $identidade.User.Value) {
    throw 'Entre em AdminControle antes de alterar a conta controlada.'
}
if ($usuario.SID.Value -eq $admin.SID.Value) {
    throw 'A conta controlada não pode ser a conta de recuperação.'
}
if (-not (Get-LocalGroupMember -SID 'S-1-5-32-544' |
    Where-Object { $_.SID.Value -eq $admin.SID.Value })) {
    throw 'AdminControle não pertence a Administradores.'
}
if (-not (Get-LocalGroupMember -SID 'S-1-5-32-545' |
    Where-Object { $_.SID.Value -eq $usuario.SID.Value })) {
    Add-LocalGroupMember -SID 'S-1-5-32-545' -Member $usuario
}
if (Get-LocalGroupMember -SID 'S-1-5-32-544' |
    Where-Object { $_.SID.Value -eq $usuario.SID.Value }) {
    Remove-LocalGroupMember -SID 'S-1-5-32-544' -Member $usuario
}
Get-LocalGroupMember -SID 'S-1-5-32-544'
Get-LocalGroupMember -SID 'S-1-5-32-545'
~~~

Encerrar a sessão antiga de user e entrar novamente para aplicar o token com os novos privilégios.
Os SIDs dos grupos funcionam em Windows em português ou inglês.
Não fornecer a senha administrativa à pessoa controlada.

## 5. Opcional: remover senha local de user

Foi uma escolha solicitada no cenário inicial, não uma exigência do controle parental.
Para futuros perfis por pessoa, senhas individuais são preferíveis: qualquer pessoa pode usar uma conta sem senha.
Somente conta LOCAL; não remove PIN Windows Hello nem senha Microsoft.
Redefinir senha administrativamente pode afetar EFS, certificados e credenciais salvas. Avaliar antes.
Se política rejeitar senha vazia, manter a senha; não reduzir a política global.

Executar em AdminControle, elevado:

~~~powershell
$ErrorActionPreference = 'Stop'
$usuario = Get-LocalUser -Name 'user'
$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Abra o PowerShell como administrador.'
}
if ($usuario.SID.Value -eq $identidade.User.Value) {
    throw 'Não remover a senha da conta em execução.'
}
if ([string]$usuario.PrincipalSource -ne 'Local') {
    throw 'Procedimento somente para conta local.'
}
if (Get-LocalGroupMember -SID 'S-1-5-32-544' |
    Where-Object { $_.SID.Value -eq $usuario.SID.Value }) {
    throw 'A conta controlada ainda é administradora.'
}
$senhaVazia = New-Object System.Security.SecureString
Set-LocalUser -SID $usuario.SID -Password $senhaVazia
Write-Host 'Senha local removida; PIN/Windows Hello não foi alterado.'
~~~

## 6. Exigir credenciais administrativas para elevação

Executar em AdminControle, com PowerShell elevado.
Salvar backup antes de alterar UAC:

~~~powershell
$ErrorActionPreference = 'Stop'
$caminho = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$backupUac = Join-Path $env:USERPROFILE (
    'UAC-anterior-{0}.reg' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
)
& reg.exe export 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' $backupUac /y
if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao salvar backup; nenhuma regra foi alterada.'
}
$regras = @{
    EnableLUA                 = 1
    ConsentPromptBehaviorUser = 1
    PromptOnSecureDesktop     = 1
    EnableInstallerDetection  = 1
}
foreach ($nome in $regras.Keys) {
    $parametros = @{
        Path = $caminho
        Name = $nome
        PropertyType = 'DWord'
        Value = $regras[$nome]
        Force = $true
    }
    New-ItemProperty @parametros | Out-Null
}
Get-ItemProperty -Path $caminho |
    Select-Object EnableLUA, ConsentPromptBehaviorUser,
        PromptOnSecureDesktop, EnableInstallerDetection
Write-Host "Backup: $backupUac"
Write-Host 'Reinicie manualmente quando for conveniente.'
~~~

ConsentPromptBehaviorUser=1 exige credenciais administrativas na área segura para elevar operações de conta padrão.
Não constitui lista de aplicativos permitidos e não bloqueia todos os instaladores por usuário.

## 7. Instalar Monitor & Control

Pacote de teste criado: MonitorAndControl/dist/MonitorAndControl-Setup-1.6.2-x64.exe.
Copiar EXE e arquivo .sha256 para o PC controlado.
Na pasta com os dois arquivos:

~~~powershell
$ErrorActionPreference = 'Stop'
$arquivo = Join-Path (Get-Location).Path 'MonitorAndControl-Setup-1.6.2-x64.exe'
$esperado = ((Get-Content -LiteralPath "$arquivo.sha256" -Raw).Trim() -split '\s+')[0]
$obtido = (Get-FileHash -LiteralPath $arquivo -Algorithm SHA256).Hash
if ($esperado -ne $obtido) {
    throw 'Hash diferente. Não executar o instalador.'
}
Write-Host 'Hash confere.'
~~~

A conferência detecta corrupção; o instalador de teste ainda não tem assinatura digital.
Fechar a cópia portátil de teste antes de instalar: o monitor usa instância única.
Executar instalador em AdminControle, autorizando instalação em Program Files.
Destino: C:\Program Files\DeviceMon. Serviço: GameHost.
Banco e logs: C:\ProgramData\SystemHelper.
Pacote inicial: localhost:5000, sem limites de exemplo e sem acesso LAN.
Não publicar a porta na internet.
A remoção exige administrador Windows; hoje não exige senha do painel.

~~~powershell
Get-Service -Name GameHost | Select-Object Name, Status, StartType
Start-Process 'http://localhost:5000'
~~~

Entrar em user, abrir o painel e cadastrar senha administrativa conhecida somente pelo responsável.
Senha já cadastrada deve ser preservada.
Em App Limits, 180 minutos = três horas. Grupo de aplicativos não limita a sessão Windows inteira.
O módulo é descrito em CONTROLE_TEMPO_PC.md e implementado experimentalmente em 1.7.0; ver TEMPO_PC_NEW.md.

## 8. Instalar NextDNS global no Windows 10

O comando Add-DnsClientDohServerAddress foi tentado neste Windows 10 e não existe.
O script anterior parou na verificação inicial, antes de alterar DNS. Não repetir o roteiro de Windows 11.

Método adotado: MSI oficial com perfil global.
No painel NextDNS, criar/selecionar perfil para o PC e copiar o ID de seis caracteres.
Executar como administrador no PC controlado.
O bloco instala o cliente e altera a resolução DNS; uma sessão remota pode ser interrompida durante mudanças de rede.

~~~powershell
$ErrorActionPreference = 'Stop'
$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Abra o PowerShell como administrador.'
}
$perfilDns = (Read-Host 'ID do perfil NextDNS (6 caracteres)').Trim()
if ($perfilDns -notmatch '^[0-9a-fA-F]{6}$') {
    throw 'ID inválido. Copie o campo ID da aba Instalação do perfil.'
}
$instalador = Join-Path $env:TEMP 'NextDNSSetup.msi'
$log = Join-Path $env:TEMP 'NextDNS-install.log'
Invoke-WebRequest -Uri 'https://nextdns.io/download/windows/stable.msi' -OutFile $instalador

$assinatura = Get-AuthenticodeSignature -FilePath $instalador
if ($assinatura.Status -ne 'Valid') {
    throw 'Assinatura digital não validada. Não instalar esse arquivo.'
}
$assinatura.SignerCertificate | Select-Object Subject

$argumentos = @(
    '/i', ('"{0}"' -f $instalador),
    '/passive', '/norestart',
    ("PROFILE={0}" -f $perfilDns),
    'UI=1', 'ARP=1', 'REPORT_DEVICE_NAME=0',
    '/L*v', ('"{0}"' -f $log)
)
$processo = Start-Process msiexec.exe -ArgumentList $argumentos -Wait -PassThru
if ($processo.ExitCode -notin @(0, 3010)) {
    throw "Falha: $($processo.ExitCode). Consulte $log"
}
if ($processo.ExitCode -eq 3010) {
    Write-Host 'Instalação concluída; reinício pendente.'
}
Clear-DnsClientCache
Get-Service -Name NextDNSService | Select-Object Name, Status, StartType
~~~

PROFILE define perfil global; o guia do fornecedor informa que a conta padrão não pode alterar perfil nem parar cliente pela interface nessa modalidade.
UI=1 mantém interface visível; ARP=1 mantém entrada em Aplicativos instalados.
REPORT_DEVICE_NAME=0 evita envio de nome/modelo por essa opção.
Categorias são definidas no painel, não na instalação.
Esse filtro também afeta AdminControle.

## 9. Categorias, teste e diagnóstico do DNS

No [painel NextDNS](https://my.nextdns.io):
1. Controle parental: selecionar categorias e serviços a bloquear.
2. Configurar SafeSearch e YouTube Restricted Mode, se desejado.
3. Lista negra: acrescentar domínios específicos.
4. Lista branca: avaliar/liberar falsos positivos.
5. Configurações: decidir retenção de logs.

Bancos, apostas e redes sociais são decisões diferentes; confirmar serviços antes de bloquear.
Guardar acesso administrativo NextDNS com o responsável e encerrar sua sessão web no navegador de user.

No PC controlado:

~~~powershell
Start-Process 'https://test.nextdns.io'
Start-Process 'https://my.nextdns.io'
~~~

Esperado: status ok, protocol DOH e clientName nextdns-windows.
O campo profile pode ser identificador interno, não o ID de seis caracteres.
Na aba Instalação do perfil escolhido, conferir mensagem verde de uso deste perfil.
Não clicar em Vincular IP: o método por aplicativo não exige isso.

Diagnóstico:

~~~powershell
Get-Service -Name NextDNSService
Get-NetAdapter | Select-Object Name, Status, InterfaceDescription
Get-DnsClientServerAddress |
    Select-Object InterfaceAlias, AddressFamily, ServerAddresses
Clear-DnsClientCache
~~~

Esses comandos não comprovam cobertura de todos os aplicativos.
Conferir IPv6, navegador com DNS próprio, VPN, troca de rede e reinício.
Não tratar resultado de um navegador como proteção absoluta contra contorno.

## 10. Reiniciar e validar em user

Reiniciar manualmente depois de salvar trabalhos; entrar diretamente em user.

- [ ] user fora de Administradores.
- [ ] AdminControle acessível e consegue elevar operações.
- [ ] Operação que exige administrador pede suas credenciais.
- [ ] GameHost ativo e painel abre.
- [ ] Alterações do painel exigem senha.
- [ ] NextDNS confirma perfil correto em user.
- [ ] Domínio inofensivo colocado temporariamente na Lista negra é bloqueado; retirar teste ao terminar.
- [ ] App de teste respeita limite individual/grupo.
- [ ] Conta padrão não remove/paralisa serviços com privilégios administrativos.
- [ ] Não declarar bloqueio de portáteis sem política específica.

Evidência relatada em 25/10/2026: proprietário confirmou instalação/configurações funcionando após reinício diretamente em user; NextDNS mostrou mensagem verde usando o perfil.
Não houve evidência de todos os itens acima. O módulo novo de tela possui implementação experimental, sem validação de logoff real.

## 11. Recuperação

Preservar senha de AdminControle. Em falha, entrar nela e consultar estado dos serviços.
Registrar código de erro sem compartilhar credenciais ou logs completos com dados pessoais.
Não remover a conta administrativa para recuperar a controlada.
Uma reversão autorizada do NextDNS pode ser feita em Aplicativos instalados; isso retira o filtro.
Reverter UAC somente depois de revisar backup e motivo; não importar automaticamente um .reg antigo.
O futuro módulo deve restaurar qualquer restrição de login que ele próprio aplique quando for removido.

## Fontes

- [Microsoft: New-LocalUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/new-localuser?view=powershell-5.1)
- [Microsoft: Set-LocalUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/set-localuser?view=powershell-5.1)
- [Microsoft: configuração UAC](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/settings-and-configuration)
- [NextDNS: MSI e perfil global](https://help.nextdns.io/t/83hsj8t/windows-client-mass-deployment-guide)
- [Guia do instalador](../installer/README.md)
- [Novo módulo de tela](CONTROLE_TEMPO_PC.md)

# Instalador Windows (teste)

Gera um assistente EXE para Windows 10/11 x64, com os quatro componentes e runtimes .NET incluídos. A compatibilidade precisa ser validada nas versões Windows alvo.

## Gerar

Requisitos: SDK .NET indicado em global.json e Inno Setup 6.7.3 (ou compatível).

Execute em PowerShell:

```powershell
.\installer\build-installer.ps1 -DotnetPath 'C:\caminho\dotnet.exe' -IsccPath 'C:\caminho\ISCC.exe'
```

Saída: dist/MonitorAndControl-Setup-1.7.1-x64.exe e arquivo SHA-256.
Cada projeto é publicado separadamente; arquivos compartilhados só são combinados se os hashes forem iguais.
Os arquivos de preparação ficam em installer-work, ignorados pelo Git. O script não remove pastas existentes.

## Instalar

O assistente exige administrador Windows, mostra a licença e instala em Program Files/DeviceMon.
Na primeira instalação: porta 5000, painel local, sem limites/horários de exemplo.
O watchdog inicia automaticamente e abre o monitor na sessão de console ativa.
O atalho do painel usa porta 5000. Se uma instalação existente usa outra porta, acesse manualmente a porta preservada.
Configure a senha no painel; use conta padrão para a pessoa controlada.

## Atualizar e remover

Atualização preserva appsettings.json e banco/histórico em ProgramData/SystemHelper.
Para atualizar instalação existente, o assistente pede confirmação antes de parar serviço e componentes do diretório instalado.
Remoção exige administrador Windows e confirmação; não exige a senha do painel.
O próprio GameHost remove o serviço e libera a proteção de arquivos de dados.
A configuração e os dados permanecem após remover; os registros de início automático dos perfis carregados são limpos somente quando apontam exatamente para esta instalação.
Instalações/remoções silenciosas de atualização são recusadas para evitar interrupção sem confirmação.
Não configura fonte de atualização remota ou firewall.

## Validação e limites

Compilação do instalador e testes existentes são etapas de geração, não aprovação de instalação.
Testar em VM limpa: instalar sem .NET, iniciar com conta padrão, reiniciar, preservar senha/regras na atualização e remover como administrador.
Validar rollback após falhas, perfis não carregados, conflito de porta e instalação anterior incompleta.
O instalador de teste não tem assinatura digital; SmartScreen pode alertar.
Não instalar a primeira versão de avaliação em máquina com dados importantes.
Fair Use License e autoria originais preservadas. Sem publicação como produto independente.

## Evidencia de geracao (12/10/2026)

Os quatro projetos compilaram em Release/win-x64 com runtime incluido. Os 29 testes existentes passaram. Inno Setup 6.7.3 compilou o assistente. Instalacao, upgrade, rollback, reinicio e remocao em Windows limpo ainda nao foram executados; tratar o pacote como versao de teste.


## NEW — Tempo por conta (1.7.0)

O novo pacote inclui módulo de tela no serviço e configuração administrativa local. Não ativa limites por padrão. Dados ficam em ProgramData/DeviceMonScreenTime, separados dos apps. Antes de usar, leia [instruções e limitações](../docs/TEMPO_PC_NEW.md). O histórico de testes 1.6.2 acima permanece como registro; 1.7.0 possui 33 testes automatizados, sem validação Windows do logoff.


## 1.7.1 — configuração integrada

Atualizar DeviceMon e GameHost juntos. O controle de tempo é configurado dentro do painel, com credenciais administrativas locais confirmadas pelo serviço. Não há janela externa de configuração. Dados da versão anterior são preservados. Veja [uso e validação](../docs/TEMPO_PC_NEW.md). Esta versão possui 38 testes automatizados; validação Windows real ainda pendente.

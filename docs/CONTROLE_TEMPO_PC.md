> Atualização 1.7.1: o fluxo atual é integrado ao painel, sem helper visual externo. Alterações são autorizadas pelo serviço usando credenciais administrativas Windows informadas no próprio painel. O plano abaixo preserva a análise histórica; o comportamento efetivo e os testes estão em [TEMPO_PC_NEW.md](TEMPO_PC_NEW.md).

# Inclusão de limite diário por usuário Windows

Data: 25/10/2026.
Base inspecionada: MonitorAndControl 1.6.2, commit 0cbdfc4cbf182f4bf561027c9b9862994e99cb51.
Branch local: codex/controle-parental.
Estado: versão 1.7.0 experimental implementada; build e 33 testes passaram. Validação de sessão/logoff em Windows ainda pendente. Nenhuma política do PC foi ativada durante o desenvolvimento. Ver TEMPO_PC_NEW.md para comportamento efetivo e limitações; o plano abaixo preserva também a evolução futura.

## Objetivo confirmado

Selecionar explicitamente a conta Windows controlada e o limite diário de cada perfil. Exemplo inicial: user com 180 minutos por dia de sessão Windows, independente do aplicativo. Contas não selecionadas permanecem sem efeito do novo módulo.
Conta administrativa AdminControle: fora do limite.
Preservar consumo após reinício. Ao esgotar, interromper uso e manter restrição até renovação diária ou autorização administrativa.

## Resultado da inspeção

Não existe limite de sessão na versão atual. UsageTracker conta apps e grupos; LimitEnforcer fecha processos. A ação block-all só encerra apps rastreados.
A implementação deve ser módulo separado da contagem por aplicativo.

## Pontos de código

- Services/UsageTracker.cs: SampleUsage e contagem de grupos; não somar totais de aplicativos para calcular tempo de tela.
- Services/WindowTracker.cs: estado bloqueado/inativo; suas consultas ocorrem na sessão do monitor, não são automaticamente válidas no serviço SYSTEM.
- Services/LimitEnforcer.cs: lógica existente deve continuar atendendo somente apps/grupos.
- Watchdog/Program.cs: WatchdogService.OnStart, CheckMonitor, IsMonitorRunning e StartMonitorInActiveSession; adicionar ciclo independente de fiscalização de sessão.
- Data/UsageDatabase.cs: banco atual compartilhado e gravável pelo usuário; não usar como fonte confiável para contador/política global.
- Web/DashboardServer.cs: novas operações de consulta e administração precisam de autorização no serviço, além da verificação da interface.
- Web/wwwroot: painel próprio de Tempo do PC, separado de App Limits.
- installer/MonitorAndControl.iss: atualização e remoção do módulo; preservar regras/estado e recuperação administrativa.
- Tests/Program.cs: testes existentes de aplicativos não cobrem limite de sessão.

## Arquitetura recomendada

Serviço GameHost/SYSTEM:
- Identificar conta por SID, não somente nome.
- Recusar selecionar SYSTEM, contas de serviço ou conta administradora para controle; validar conta local padrão.
- Enumerar e identificar sessões, inclusive troca de usuário. O IsMonitorRunning atual aceita uma instância em qualquer sessão, o que exige correção para não confundir administrador e usuário controlado.
- Contar tempo uma vez por usuário e persistir contador protegido em diretório próprio dentro de Protected, separado do banco de apps.
- Contagem e fiscalização independentes do processo DeviceMon e do canal de atualização remota; download de atualização não deve paralisar esse controle.
- Usar temporizador monotônico para duração; data local apenas para janela diária. Tratar retrocesso do relógio, sono, retomada e virada do dia.
- Persistir de forma atômica com cópia de recuperação; definir perda máxima de contagem entre checkpoints.
- Publicar estado de leitura para o painel sem expor gravação de política/consumo ao usuário padrão.

Canal administrativo local:
- Contrato estreito para consultar estado, alterar limite, conceder bônus e desativar regra.
- Canal autenticado e com ACL; serviço deve validar identidade/autorização, limites e SID de destino.
- Não confiar apenas em arquivo trigger, token ou senha contidos no banco atual gravável por Users.
- Desenho da autenticação do serviço e migração de credenciais precisa ser resolvido antes de implementar as operações do painel; não duplicar autenticação de modo improvisado.
- Alternativa inicial: configuração por helper elevado, usando credenciais Windows administrativas; painel comum somente consulta.

## Comportamento proposto

- Contar sessão de console ativa e desbloqueada da conta selecionada.
- Não cobrar tela bloqueada, suspensão, hibernação nem tempo em AdminControle.
- Por padrão, contar sessão desbloqueada mesmo sem teclado/mouse, cobrindo vídeos e controles de jogo. Pausa por inatividade seria opção explícita.
- Avisar quando restarem 10, 5 e 1 minuto.
- Ao atingir o limite configurado do perfil (exemplo: 180 minutos), encerrar somente a sessão controlada por API Windows.
- Avisar que logoff fecha programas e pode perder trabalho não salvo.
- Continuar fiscalizando novo login da conta esgotada até renovação ou bônus.

Limite importante: logoff repetido impede permanência, mas pode permitir um intervalo curto após novo login. Não equivale a negar login antes de entrar.
Se o requisito for impedir autenticação da conta esgotada, avaliar um bloqueio de login suportado pelo Windows com restauração segura na virada do dia, desinstalação e recuperação. Não desabilitar conta permanentemente sem esse ciclo de recuperação.
Somente chamar LockWorkStation é insuficiente, pois permite desbloquear e continuar.

## Interface

Tempo do PC:
- Conta Windows e SID selecionado.
- Ativar controle, minutos/dia (180), usado e restante.
- Definição clara de contagem, horário de renovação e estado do serviço.
- Bônus de hoje, liberar temporariamente e desativar regra, com autorização.
- Indicar recurso indisponível se o serviço não estiver instalado; não simular proteção.
- Nunca converter grupo de apps em regra global silenciosamente.

## Plano de implementação

1. Módulo de política/contagem testável, sem chamar Windows nos testes.
2. Armazenamento protegido e recuperação; conta/SID explicitamente configurados.
3. Adapter de sessões Windows no GameHost e ciclo independente.
4. Canal administrativo seguro/helper elevado e consulta de status.
5. Avisos no monitor e painel Tempo do PC.
6. Integração de instalação/atualização/remoção e documentação.
7. Testes em Windows 10 Pro x64 com duas contas, antes de ativar no PC controlado.

## Testes de aceitação

- Limite curto de 2 minutos em conta descartável, seguido de validação de 180 minutos.
- Apps diferentes, Explorer, vídeo, sem apps cadastrados e apps simultâneos.
- Fechar DeviceMon, reiniciar PC e reiniciar serviço sem zerar consumo.
- Login de AdminControle não consome nem sofre bloqueio.
- Troca rápida de conta e monitor aberto na sessão errada.
- Bloquear/desbloquear tela, suspender/retomar e mudar o relógio.
- Virada diária, bônus administrativo e contador persistido.
- Conta padrão não altera política/contador nem autoriza bônus por requisição forjada.
- Novo login após esgotar, intervalo de exposição e comportamento documentados.
- Recuperação após falha, serviço ausente e remoção autorizada.
- RDP e múltiplas sessões somente podem ser declarados suportados após testes específicos.

## Evidência existente do proprietário

Proprietário relatou que instalação/configurações persistiram após reinício diretamente na conta user. Isso valida o cenário anterior, não valida este novo módulo.
Nenhum teste de limite global foi executado.

## Referências técnicas Microsoft

- [WTSLogoffSession](https://learn.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtslogoffsession): logoff de sessão específica.
- [Estado de sessão WTSINFOEX_LEVEL1](https://learn.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsinfoex_level1_w): estado bloqueado/desbloqueado.

## Requisito refinado: seleção de conta e perfis independentes

Atualização de escopo: 25/10/2026, solicitada pelo proprietário antes da implementação.
A ideia visual é um seletor de perfis semelhante ao NextDNS; não significa copiar a arquitetura, usar a API do NextDNS ou ligar conta Windows a perfil DNS automaticamente.

### Comportamento obrigatório da primeira versão de tempo de tela

- Listar contas Windows locais elegíveis e permitir selecionar explicitamente a conta controlada.
- Permitir definir minutos por dia para cada conta selecionada; 180 é o exemplo inicial, não uma constante global.
- Suportar registros independentes para mais de uma conta controlada no desenho, painel e armazenamento do módulo.
- Não aplicar regra a todas as contas nem inferir alvo pelo usuário do painel ou pela sessão ativa.
- Contas sem política ativa não sofrem cobrança, avisos, logoff ou restrição do novo módulo.
- Excluir contas administrativas e de sistema da seleção inicial; manter AdminControle disponível para recuperação.
- Exibir nome amigável do perfil e identidade Windows vinculada antes de salvar.
- Conta removida invalida o vínculo; outra conta criada com o mesmo nome não herda política ou consumo.
- Renomear conta não deve zerar consumo, pois a identidade é o SID.

Exemplo de resultado esperado:

| Perfil | Conta Windows | Limite diário | Comportamento |
|---|---|---|---|
| Uso diário | user, SID selecionado | 180 minutos | Controlada pelo módulo |
| Outro usuário | segunda conta padrão, outro SID | 60 minutos, se configurado | Cota independente |
| Administração | AdminControle | Sem política | Sem efeito do módulo |
| Conta não configurada | qualquer outra | Sem política | Sem efeito do módulo |

### Perfil do produto e conta Windows

A relação inicial é um perfil para uma conta Windows local. Não usar nomes como user como chave do banco.
Proposta de contrato, ainda sem classes/tabelas implementadas:

| Entidade | Identidade e dados mínimos |
|---|---|
| Perfil | ProfileId estável, nome amigável, WindowsUserSid único, ativo/inativo |
| Política de tela | ProfileId, Enabled, DailyLimitMinutes, regra/fuso de renovação, versão |
| Consumo diário | ProfileId, dia da política, duração acumulada, checkpoint |
| Bônus diário | ProfileId, dia, minutos adicionais, autor e motivo |
| Estado de restrição | ProfileId, SID e sessão atingidos, motivo, início/expiração |
| Auditoria | Perfil alvo, SID, autor da alteração, ação, resultado, instante com fuso |

Armazenamento autoritativo no serviço, protegido contra escrita da conta padrão.
Nenhuma chave global como TodayUsedSeconds, sem identidade de conta.
Validar limite e bônus; proposta inicial de limite diário entre 1 e 1440 minutos.
Exibir valor em horas/minutos na interface e armazenar unidade explícita; três horas = 180 minutos.
Um mesmo SID não pode criar dois perfis concorrentes para contornar o limite.
Mudança de vínculo deve ser operação explícita e auditada, nunca reaproveitar consumo silenciosamente.

### Painel proposto

Seletor de perfil no topo do módulo:
- Criar/selecionar perfil e escolher conta Windows elegível.
- Mostrar nome do perfil, nome da conta, SID em detalhes, limite, usado, bônus e restante.
- Editar minutos/dia, ativar/desativar e conceder bônus somente para o perfil exibido.
- Confirmar claramente a conta atingida em toda operação administrativa.
- Consultas de usuário padrão, se oferecidas, limitadas ao próprio estado; administração de outros perfis exige autorização.
- O seletor de perfil não é um mecanismo de autenticação.

A regra deve continuar sendo aplicada mesmo quando o responsável deixa outro perfil selecionado no painel.

### Preparação para evolução futura

O cadastro de perfil pode futuramente delimitar:
- Regras de aplicativos, grupos, horários e estatísticas.
- Preferências de avisos e relatórios.
- Integrações de filtro de conteúdo específicas por conta, se um mecanismo adequado for escolhido.

Esses recursos não fazem parte da implementação atual do módulo de tela.
Preservar comportamento atual de apps/grupos como legado global; marcar esse escopo no painel.
Não transformar automaticamente regras globais em regras de uma conta nem afirmar que já estão isoladas.
No futuro, migração deve ser explícita, com destino de perfil escolhido e compatibilidade de backups.
Novos contratos de tela sempre incluem ProfileId e SID validado; extensão para aplicativos pode reutilizar ProfileId sem reescrever a identidade.
Não criar autenticação, painel, serviço Windows ou banco duplicados por conta.
O NextDNS instalado permanece global; perfis do Monitor & Control não mudam o perfil DNS.

### Serviço e sessões

- Resolver SID pelo token/identidade Windows da sessão; nome é rótulo, não autorização.
- Processar apenas sessões de contas com política ativa.
- Corrigir instância/monitor por sessão: um DeviceMon em AdminControle não pode fazer o serviço ignorar user.
- O serviço conta o uso de cada perfil independentemente de apps abertos e de quem abre o painel.
- Para sessões simultâneas do mesmo perfil, definir contagem única de tempo real, sem multiplicar; suporte RDP depende de testes próprios.
- Ao esgotar A, não encerrar, bloquear, alterar privilégios ou zerar contador de B.
- Atualização de política de A não altera B; bônus e reset devem identificar um perfil específico.
- Serviço revalida alvo e autorização em cada operação; não confiar só no ProfileId recebido do navegador.
- Nenhuma política deve bloquear a conta de recuperação administrativa.
- Falha de identificação de conta não pode resultar em bloquear o PC inteiro.

### Critérios adicionais de aceitação

- user com 180 minutos, segunda conta padrão com limite diferente e administrador isento.
- Abrir painel como administrador e aplicar regra à conta selecionada, não à conta da sessão do navegador.
- Trocar perfil na UI sem mudar o alvo de uma requisição já iniciada.
- Renomear conta mantém vínculo; remover/recriar o mesmo nome não reaproveita o SID.
- Reinício preserva separadamente contadores de A e B.
- Bônus para A não aumenta B; esgotamento de A não encerra B.
- Perfil desativado e conta sem perfil não são atingidos.
- Pedido forjado de outra conta não concede bônus nem altera política.
- Backup/restore mantém vínculo de SID; em outro PC, exigir remapeamento explícito, sem aplicar por coincidência de nome.
- Desinstalação restaura somente restrições aplicadas pelo módulo e preserva acesso administrativo.
- Confirmar bloqueio ao término, renovação diária e recuperação antes de declarar pronto.

## Relação com o roteiro operacional

Ver [ROTEIRO_CONFIGURACAO_PC.md](ROTEIRO_CONFIGURACAO_PC.md).
O roteiro descreve contas/UAC/instalação/DNS já utilizados.
Este documento reúne especificação e evolução. A implementação experimental e as diferenças frente ao plano estão registradas em TEMPO_PC_NEW.md.
O foco imediato é tempo de tela por conta; controle de aplicativos e DNS por perfil ficam para evolução posterior.

[Implementacao NEW e validacao pendente](TEMPO_PC_NEW.md)

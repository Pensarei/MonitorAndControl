# Roteiro — observação parental com aviso e acesso protegido

Data: 25/10/2026.
Estado: especificação proposta; nenhum recurso de captura foi implementado ou ativado.
Base: Monitor & Control 1.7.3. Complementa ROTEIRO_NOVOS_MODULOS.md.
Escopo: PC sob administração do responsável, conta padrão previamente selecionada, observação transparente.
As decisões abaixo são requisitos planejados, não garantias já presentes no aplicativo.

## 1. Comportamento e limites

- Aviso discreto, legível e persistente durante toda a captura, identificando os recursos ativos e o responsável.
- Exemplo: “Supervisão ativa — tela e microfone — responsável: Conta Família”.
- Exibir notificação ao iniciar e manter faixa compacta ou indicador equivalente na área visível da sessão. Não depender apenas de ícone oculto na bandeja.
- O usuário padrão não terá comando no aplicativo para encerrar ou ocultar esse indicador.
- A supervisão é informada na configuração inicial da conta e nos acessos posteriores; não há captura escondida.
- O início e o término administrativo pertencem ao responsável autenticado; não exigir confirmação a cada sessão na interface do nosso aplicativo.
- Respeitar solicitações de permissão, indicadores e restrições do Windows, navegador e hardware. A aplicação não promete eliminá-los.
- Não impedir desligamento físico, desconexão, tampa/interruptor de privacidade, retirada de webcam ou outras proteções do sistema.
- Não transmitir contas administrativas, tela de login, área de trabalho segura, outras contas ou sessões sem política.
- Visualização apenas: sem teclado/mouse remoto, gravação, download de capturas ou execução de comandos no PC.
- Tela, microfone e webcam são três permissões independentes, desligadas por padrão.

## 2. Configuração inicial — somente no próprio PC

1. Administrador Windows abre a configuração local e autoriza pelo UAC.
2. Seleciona explicitamente a conta Windows controlada, vinculada pelo SID.
3. Lê e confirma o funcionamento transparente e os limites de privacidade.
4. Habilita individualmente os recursos permitidos e define duração máxima.
5. Cadastra o responsável e verifica o endereço de e-mail de alertas.
6. Cria senha exclusiva da supervisão, diferente da senha do painel.
7. Configura segundo fator independente do e-mail e pareia o dispositivo observador.
8. Testa alerta, aviso local e interrupção de emergência antes de liberar o recurso.
9. Armazena política e estado de bloqueio em área protegida pelo serviço.
10. Mudanças de credenciais, observadores e permissões exigem nova autorização local.

Não aceitar habilitação por simples edição de banco/arquivo gravável pela conta padrão.
Não reutilizar tokens do painel como autorização de captura.

## 3. Fluxo de início no painel

1. Responsável entra no painel autenticado por conexão cifrada.
2. Escolhe PC, conta, recurso e duração; não selecionar todas as contas automaticamente.
3. Servidor verifica política local, dispositivo pareado e origem autorizada.
4. Exigir senha exclusiva novamente e segundo fator para cada nova sessão.
5. Criar autorização de uso único, curta, vinculada ao responsável, PC, SID, sessão Windows, recursos e observador.
6. Serviço valida novamente a autorização; navegador não decide permissões.
7. Agente da sessão mostra o aviso local. Sem confirmação de exibição, não capturar.
8. Registrar o início e preparar o alerta; somente depois liberar a transmissão ao observador.
9. Se aviso falhar durante a captura, encerrar a transmissão.
10. Encerrar por ação do responsável, bloqueio de emergência ou qualquer condição automática de parada.

A senha não deve viajar em URL, e-mail, log ou parâmetro de processo.
Guardar apenas hash de senha com sal e custo adequado; proteger chaves com recursos seguros do Windows.
Criptografia não compensa senha fraca, roubo da conta ou comprometimento do PC observador.

## 4. Rede e transmissão

Primeira versão: mídia apenas na rede local autorizada e para dispositivo pareado.
Acesso externo continua limitado a resumo e concessão de tempo, sem mídia.

- HTTPS para painel e sinalização; validar certificados e identidade do PC.
- Transporte de mídia cifrado, com bibliotecas mantidas e protocolos estabelecidos; não criar criptografia própria.
- Não expor porta 5000, mídia ou sinalização diretamente à internet.
- Não habilitar retransmissão externa de mídia na primeira versão.
- Aplicar autorização tanto ao início quanto à entrega de cada canal de mídia.
- Credenciais de mídia curtas e específicas; uma sessão do painel não permite assinar qualquer transmissão.
- Um observador por sessão; novo observador exige nova autorização.
- Limitar duração, largura de banda e resolução; encerrar em perda de conexão, sem reconectar automaticamente.
- Firewall com escopo mínimo. CORS não é autenticação nem isolamento de rede.
- IP privado não prova presença física na LAN. VPN, encaminhamento e proxy precisam entrar no modelo de ameaça.
- Separar o canal externo de bônus do serviço de mídia; o primeiro não pode abrir túnel, iniciar captura ou fornecer endereços de mídia.
- Documentar e testar a fronteira real de rede antes de afirmar “apenas LAN”.

Proposta inicial: sessões de até 10 minutos; renovar exige nova autenticação e novo alerta.
A duração final é configurável pelo administrador dentro de um teto do produto.

## 5. Aviso ao responsável por e-mail

Enviar no início efetivo, na tentativa de acesso suspeita e no encerramento/bloqueio.
Conteúdo:
- Identificador único do evento e da sessão.
- Horário UTC e horário local com fuso.
- PC e conta Windows observada, usando nome amigável; SID completo só na auditoria local quando necessário.
- Recursos ativos e duração máxima.
- Conta do responsável autenticado e identificador do dispositivo pareado.
- IP de origem observado pelo servidor e indicação de conexão local/remota.
- Resultado: solicitado, iniciado, recusado, encerrado ou bloqueado.
- Instrução de emergência e identificador público da credencial utilizada, sem o segredo.

Não enviar senha, hash, segundo fator, cookie, token de transmissão, imagem ou áudio.
Nome do navegador, IP e dispositivo são indícios; não comprovam identidade nem invasão.
Só confiar em cabeçalhos de proxy quando o proxy estiver explicitamente cadastrado.

Para a primeira versão, exigir aceite do alerta pelo serviço de envio antes de liberar mídia.
Aceite do servidor de e-mail não comprova entrega à caixa nem leitura pelo responsável.
Se envio, fila protegida ou auditoria falhar, recusar o início. Não usar e-mail como único mecanismo de segurança.

## 6. Parada e bloqueio de emergência

Ações:
- “Encerrar sessão”: termina a transmissão identificada.
- “Bloquear supervisão deste PC”: termina todas as transmissões, revoga autorizações e impede novas ativações.
- Bloqueio persiste após reinício, atualização e troca de usuário.
- Desbloqueio somente no próprio PC, por administrador Windows com UAC e nova verificação da configuração.
- Nenhum comando por e-mail ou painel remoto pode desbloquear.

E-mail:
- Reutilizar transporte e identificação de dispositivos existentes, acrescentando autenticação específica do comando.
- Remetente permitido, assunto ou identificador de evento isoladamente não autorizam ações.
- Exigir autorização verificável ligada ao PC e à ação, com expiração e proteção contra repetição.
- Escolher mecanismo antes de implementar: comando assinado de dispositivo cadastrado ou confirmação autenticada de ação limitada.
- Link recebido por e-mail pode abrir página de confirmação; GET, prévia ou scanner de links nunca executam bloqueio.
- Se houver credencial de emergência por e-mail, permitir somente bloqueio, nunca observar, desbloquear ou alterar políticas.
- Tratar comandos repetidos de modo idempotente e devolver confirmação somente após aplicação no serviço.
- Restringir o processamento a comandos estruturados; nunca executar código recebido por e-mail.

E-mail pode atrasar ou ficar indisponível. O painel deve oferecer bloqueio autenticado direto.
Atraso do e-mail não pode manter transmissão sem observador: usar heartbeat, prazo curto e encerramento automático.
Se PC estiver offline, mostrar comando pendente; não afirmar que o bloqueio foi aplicado.

## 7. Auditoria local

Registrar início, tentativa recusada, autenticação inválida, renovação, término e mudança de política.
Campos mínimos:
- ID do evento, ID da sessão e ID de correlação do comando.
- UTC, fuso e tempo monotônico para duração.
- PC, SID e ID da sessão Windows.
- Responsável, dispositivo pareado, origem observada e resultado.
- Recursos solicitados/efetivos, duração e motivo do encerramento.
- Versão do app e identificador da política.
- Envio de alerta, estado do comando de emergência e confirmação do serviço.

Não registrar segredos nem conteúdo capturado.
Armazenar com acesso restrito, rotação e retenção limitada; propor 30 dias como padrão a validar.
Usar sequência e verificação de integridade para detectar lacunas; opcionalmente enviar metadados a destino independente.
Não prometer log inviolável: administrador/SYSTEM ou sistema comprometido pode alterar dados e chaves locais.
Permitir revogar dispositivo e credencial suspeitos a partir dos eventos, com autorização administrativa apropriada.
Não bloquear automaticamente um IP como única resposta: NAT e endereços dinâmicos podem atingir pessoas legítimas.

## 8. Sessão Windows e proteção do indicador

Agente de captura com privilégio mínimo na sessão correta, separado do serviço e do painel.
Canal entre agente e serviço verifica identidade, sessão e autorização.
Não capturar usando contexto SYSTEM diretamente na sessão 0.
Não tornar processo invisível nem usar técnicas de persistência oculta ou resistência a ferramentas do sistema.

O aplicativo não oferece ao usuário padrão botão de parada.
Proteção contra encerramento segue apenas permissões normais do Windows.
Se agente ou indicador for encerrado, a captura termina; registrar a interrupção.
Não relançar silenciosamente a captura após falha, troca de conta ou reinício.

Encerrar também em:
- Bloqueio, logout, suspensão ou troca de usuário.
- Mudança da conta observada para administradora.
- Expiração da autorização, duração ou segundo fator revogado.
- Perda do observador, da política, da auditoria ou do indicador.
- Revogação de permissão pelo Windows ou indisponibilidade do dispositivo.

## 9. Redução de exposição

- Iniciar por compartilhamento de uma janela quando viável; tela inteira exige escolha explícita do responsável.
- Avisar sobre possível exposição de conversas, notificações e terceiros.
- Microfone é diferente de áudio do sistema; áudio do sistema fica fora do escopo inicial.
- Webcam não habilita microfone implicitamente.
- Nenhuma gravação, histórico de frames, cache persistente ou anexo de mídia.
- Examinar risco de capturar conteúdo sensível e definir restrições adicionais antes do piloto.
- Excluir console administrativo, acesso remoto com área segura e contas sem política.
- Falhas devem parar a transmissão, preservando o controle de tempo que funciona de forma independente.

## 10. Etapas e testes de aceite

1. Política local, senha exclusiva, segundo fator, pareamento e auditoria; sem captura.
2. Parada/bloqueio de emergência e alertas com testes de atraso, repetição e falsificação.
3. Tela com aviso persistente, um observador, duração curta e restrição LAN verificada.
4. Piloto supervisionado e revisão de segurança antes de habilitar por padrão em qualquer instalação.
5. Microfone separado; depois webcam, cada um com nova revisão e indicadores próprios.

Aceite obrigatório:
- Usuário padrão vê aviso claro, mas não recebe botão de encerramento do aplicativo.
- Captura nunca continua sem indicador nem atravessa troca de sessão.
- Senha do painel sozinha, remetente falsificado e dispositivo não pareado não iniciam mídia.
- Autorização expirada/repetida, recurso não permitido e origem externa são recusados.
- Nenhum segredo aparece em logs, notificações ou URL.
- Bloqueio corta mídia ativa, revoga sessões e persiste após reinício.
- Desbloqueio remoto, por e-mail ou alteração de arquivo pela conta padrão não funciona.
- Falha de câmera/microfone ou parada física não é contornada.
- Negação de serviço não impede o funcionamento do limite diário já existente.

## 11. Pendências antes de programar

Escolher bibliotecas de captura/transporte, fluxo de segundo fator e autenticação dos comandos de e-mail.
Definir credenciais por responsável, recuperação local, fronteira LAN, política de certificados e retenção.
Revisar infraestrutura necessária sem contratar serviços nem expor portas durante o planejamento.
Avisos e formulários entram no sistema de idiomas oficial, incluindo pt-br.
Manter menu, cartões e hierarquia visual existentes; recurso recebe NEW somente quando implementado.

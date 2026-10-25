# Roteiro de novos módulos

Data: 25/10/2026.
Base: 1.7.3, branch codex/controle-parental.
Estado: planejamento; este documento não implementa nem ativa recursos.
Preservar o menu lateral, a identidade visual e a hierarquia do projeto oficial.

## 1. Tradução e pt-BR — primeira entrega

### Estrutura encontrada
- Dicionários: Web/wwwroot/i18n/{en,de,es,fr,ru}.json.
- Web/wwwroot/dashboard.js: loadTranslations, t e applyTranslations; inglês funciona como texto-base, sem carregar en.json.
- Web/wwwroot/index.html: seletor set-language.
- Web/DashboardServer.cs: AllowedLanguages e validação de configuração/restauração de backup.
- Web/wwwroot/screen-time.js e a seção Tempo do PC ainda possuem textos fixos em português.

### Trabalho previsto
1. Adicionar pt-br.json, opção Português (Brasil) e identificador pt-br na validação do servidor.
2. Usar as mesmas chaves/textos-base da estrutura atual; não criar um segundo sistema de idiomas.
3. Traduzir com IA os textos existentes e revisar termos, variáveis, avisos e plurais. Não incluir dados reais de usuários na tradução.
4. Extrair os textos do módulo Tempo do PC para chaves consistentes em inglês e traduzir para en, de, es, fr, ru e pt-br.
5. Tratar mensagens dinâmicas, erros e motivos de exclusão com códigos estáveis e parâmetros; não depender de traduzir frases concatenadas recebidas do serviço.
6. Atualizar os textos ao trocar o idioma sem apagar a conta selecionada, valores não salvos ou o estado da confirmação.
7. Preservar nomes reais de contas e aplicativos, SIDs, valores e conteúdo técnico que não deve ser traduzido.
8. Formatar datas e durações conforme o idioma, mantendo o dia da cota definido pelo relógio local do PC controlado.

### Aceite
- Nenhuma chave ausente nas seis línguas; placeholders preservados.
- Troca de idioma traduz menu, formulário, tabela, confirmação, mensagens e estados vazios.
- Preferência persiste; configuração e backup aceitam pt-br.
- Sem mistura involuntária de idiomas e sem alteração da lógica de controle.

## 2. Acesso remoto ao painel — segunda entrega

### Situação atual
- O código já tem EnableRemoteDashboard e DashboardBindAddress.
- O instalador usa loopback: acesso pela rede vem desativado.
- O servidor atual usa HTTP; localhost identifica o próprio dispositivo, não é um endereço público.
- As rotas de edição de tempo exigem loopback e autorização administrativa Windows.
- Tornar o endereço acessível não cria automaticamente autorização segura para edição remota.

### Separação de acesso
| Acesso | Escopo planejado |
|---|---|
| Próprio PC | Configuração administrativa completa, conforme permissões |
| Rede local confiável | Painel autenticado; observação com autorização específica e aviso local persistente |
| Fora da rede | Consultar resumo e conceder bônus limitado a regras já existentes |
| Qualquer origem | Tela, microfone e webcam desligados por padrão |

### Etapas
1. Exibir endereço LAN correto na interface; suportar mudança de IP e revogação do acesso.
2. Definir HTTPS, instalação/renovação de certificados e regras de firewall restritas.
3. Definir uma conexão privada autenticada para acesso externo. Avaliar conexão privada por dispositivo ou agente de comandos de saída; não expor diretamente a porta 5000 à internet.
4. Autenticar responsável e dispositivo; prever segundo fator, expiração, bloqueio por tentativas, encerramento de sessão e revogação.
5. Criar permissões separadas: visualizar resumo, conceder bônus, editar políticas e iniciar observação.
6. Criar operação remota específica para bônus; nunca remover a checagem local/UAC das rotas administrativas existentes.
7. Armazenar a delegação administrativa no serviço protegido, concedida localmente por administrador.
8. Vincular cada comando ao PC, SID/perfil, regra existente, responsável, quantidade e validade. Impor teto e impedir repetição.
9. Registrar antes/depois, responsável, horário, conta e resultado; informar quando o PC estiver offline. Não confirmar alteração antes da aplicação pelo serviço.
10. Processar bônus de forma idempotente; comando atrasado não concede minutos no dia seguinte.

### Limites iniciais
- Fora da rede: bônus de tempo geral ou de aplicativo já configurado, dentro de teto definido localmente.
- Sem criação de contas, instalação de programas, terminal, alteração de senha, remoção de proteção ou captura de mídia por esse canal.
- Um túnel/VPN fornece transporte, não substitui as permissões da aplicação.
- IPv4 privado não comprova acesso físico à LAN: VPN e proxy também podem alcançar esses endereços.

### Aceite
Acesso sem login é recusado; permissões são verificadas no servidor; bônus não afeta outras contas.
Comandos repetidos, expirados, fora do teto e para outra conta/dispositivo são recusados.
Revogação interrompe novas ações. Nenhuma rota administrativa é liberada apenas por estar em rede local.

## 3. Observação assistida — tela, microfone e webcam

### Limite de produto
Somente observação transparente, com política administrativa local e aviso persistente. Não implementar captura oculta, supressão de avisos/LEDs, gravação escondida ou acesso permanente.
Cada recurso tem permissão independente e nasce desligado. A permissão de ver a tela não autoriza câmera ou microfone.

### Dificuldades técnicas
- GameHost roda como serviço na sessão 0; captura deve ocorrer por agente na sessão interativa autorizada, com privilégio mínimo.
- Identificar a sessão correta: troca de usuário, várias sessões, bloqueio, desconexão e suspensão.
- Acesso de câmera/microfone depende das permissões do sistema e da disponibilidade do hardware.
- Se a captura ocorrer em navegador, obter permissão no PC controlado; getUserMedia executado no navegador do responsável acessa os dispositivos do responsável.
- Captura no navegador exige contexto seguro e permissão. HTTP por IP da LAN não equivale à exceção de localhost.
- Vídeo ao vivo exige codificação e controle de banda, CPU, latência e reconexão.
- A captura pode conter senha, conversa privada, notificações e terceiros; a minimização precisa fazer parte do projeto.

### Desenho inicial
1. Primeira versão: somente compartilhar tela, visualização sem teclado/mouse remoto, um observador por vez.
2. Solicitar início na sessão correta; mostrar responsável solicitante, recurso e duração.
3. Exibir indicador discreto, legível e persistente durante toda a transmissão. O aplicativo não oferece botão de parada à conta padrão; o responsável controla a sessão. Respeitar permissões do sistema e interrupções físicas.
4. Usar transporte cifrado e sessão curta, vinculada ao observador e à conta previamente autorizada na política local.
5. Encerrar no bloqueio, troca de conta, desconexão do observador, revogação ou limite de duração.
6. Não restaurar a transmissão automaticamente ao reiniciar ou reconectar.
7. Não salvar gravação, frames, áudio ou vídeo em disco por padrão; auditoria contém metadados, não conteúdo.
8. Microfone e webcam entram apenas em etapas posteriores e separadas, com política independente, permissões do sistema e indicadores específicos.
9. Recusar captura de sessão administrativa, tela de login e área de trabalho segura do Windows.
10. Garantir que URLs de mídia não sejam públicas nem reutilizáveis.

### Restrição à rede local
Definir uma fronteira verificável de autorização, pareamento e transporte para mídia.
Não confiar apenas em esconder botões ou detectar endereço 192.168.x.x.
O canal externo de comandos não pode encaminhar mídia, sinalização ou pedidos de captura.
Se não for possível demonstrar o isolamento, manter o recurso indisponível.

### Aceite
Não existe fluxo que inicia ou mantém captura sem política administrativa explícita e aviso visível.
Outro usuário, outro dispositivo ou sessão expirada não acessa a transmissão.
Troca/bloqueio de sessão e revogação interrompem imediatamente a captura.
O canal externo de bônus não consegue iniciar nem receber mídia.

## 4. Ordem de implementação

1. pt-br e internacionalização completa do módulo de tempo.
2. Acesso LAN autenticado e HTTPS.
3. Delegação limitada de bônus e acesso externo autenticado, sem mídia.
4. Compartilhamento de tela com aviso persistente e restrito à LAN.
5. Avaliar separadamente microfone e webcam após validar isolamento e privacidade.

Cada entrega terá documentação, marca NEW no README quando implementada, testes específicos, instalador e aceite manual.
Este roteiro não autoriza abrir portas, contratar serviços, ativar captura ou publicar infraestrutura.

## 5. Fontes técnicas

- Serviços e sessões Windows: https://learn.microsoft.com/en-us/windows/win32/services/interactive-services
- Permissões e contexto seguro de câmera/microfone: https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
- Conectividade WebRTC e servidores de retransmissão: https://webrtc.org/getting-started/peer-connections


Detalhamento atualizado: [Observação parental com aviso e acesso protegido](ROTEIRO_OBSERVACAO_PARENTAL.md).

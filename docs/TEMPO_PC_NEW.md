# Tempo do PC — NEW — 1.7.2

No menu lateral oficial, abra **Tempo do PC** e selecione a conta Windows no campo **Conta**.
Defina os minutos por dia (180 = 3 horas), o bônus de hoje e a ativação. Cada conta mantém sua própria regra e consumo; administradores ficam excluídos.

Ao salvar, confira o nome da conta e confirme a autorização nativa do Windows (UAC).
O painel não pede nem recebe a senha do Windows. Administrador sem senha confirma o UAC conforme a política do Windows; usuário padrão precisa da autorização de um administrador.
A senha de login do painel continua independente.

Pedidos de alteração ficam no serviço por até dois minutos, têm uso único e preservam a conta e os valores selecionados.
A gravação exige um processo com autorização administrativa elevada. Cancelar o UAC não salva a alteração.
A configuração de tempo permanece disponível somente no próprio PC.

A contagem considera a sessão ativa e desbloqueada, independente do aplicativo.
Ao esgotar a cota, o serviço encerra a sessão controlada e volta a encerrá-la em novas entradas enquanto a cota estiver esgotada.
O controle não impede a autenticação inicial do Windows. Arquivos abertos podem ter alterações não salvas.
A cota renova no dia local seguinte. Contas sem regra e administradores não são afetados.

O instalador agora aguarda a saída dos processos antes de remover os arquivos.
Se encontrar cópia em execução em outra pasta, pede confirmação indicando seu caminho.
Falha ao encerrar cancela a remoção. A configuração preservada em appsettings.json é intencional.

Validação: compilação e 38 testes automatizados aprovados. Em 25/10/2026, o responsável confirmou teste aprovado na conta controlada: contagem, encerramento ao atingir a cota e novo encerramento ao entrar com a cota esgotada. UAC e desinstalação continuam com validação manual específica pendente.

A lista de seleção mostra somente contas habilitadas que não são administradoras (1.7.3).

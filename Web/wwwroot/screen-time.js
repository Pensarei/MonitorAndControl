async function screenApi(url, options) {
  try { return await api(url, options); }
  catch (error) {
    let message = error.message;
    try { message = JSON.parse(message).error || message; } catch (_) {}
    throw new Error(message);
  }
}
// Screen-time view shares the official dashboard navigation, authentication and visual components.
let screenData = null;
let screenDirty = false;
let screenLoading = false;
let screenPending = null;
let screenBusy = false;
const screenElement = id => document.getElementById('screen-' + id);
function screenDuration(seconds) {
  return Math.floor(seconds / 3600) + 'h ' + Math.floor(seconds % 3600 / 60) + 'm';
}
function screenSelectedProfile() {
  return screenData?.profiles.find(p => p.userSid === screenElement('account').value);
}
function screenRenderSelection(populate) {
  const sid = screenElement('account').value;
  const account = screenData?.accounts.find(a => a.sid === sid);
  const profile = screenSelectedProfile();
  screenElement('account-name').textContent = account?.name || 'Selecione uma conta';
  screenElement('account-sid').textContent = account?.sid || '—';
  screenElement('account-help').textContent = account && !account.eligible ?
    account.exclusionReason + '. Uma regra antiga pode ser desativada, mas não ativada.' :
    'Cada conta tem sua própria cota; as demais não são alteradas.';
  screenElement('used').textContent = profile ? screenDuration(profile.usedSeconds) : '0h 0m';
  screenElement('remaining').textContent = profile?.enabled ? screenDuration(profile.remainingSeconds) : 'Sem limite';
  screenElement('allowance').textContent = profile ? profile.dailyMinutes + ' min/dia' + (profile.bonusMinutes ? ' + ' + profile.bonusMinutes + ' min hoje' : '') : 'Nenhuma regra aplicada';
  screenElement('state').textContent = profile?.enabled ? (profile.remainingSeconds <= 0 ? 'Cota esgotada' : 'Ativo') : 'Sem controle';
  const editable = !!account && (account.eligible || !!profile);
  screenElement('save').disabled = !editable || !!screenData?.error;
  screenElement('enabled').disabled = !!account && !account.eligible;
  if (populate) {
    screenElement('minutes').value = profile?.dailyMinutes ?? 180;
    screenElement('bonus').value = profile?.bonusMinutes ?? 0;
    screenElement('enabled').checked = profile?.enabled ?? false;
    if (account && !account.eligible) screenElement('enabled').checked = false;
    screenDirty = false;
  }
}
function screenRenderTable() {
  const body = screenElement('profiles');
  body.replaceChildren();
  (screenData?.profiles || []).forEach(profile => {
    const row = document.createElement('tr');
    [profile.name, profile.dailyMinutes + ' min', screenDuration(profile.usedSeconds),
      profile.enabled ? screenDuration(profile.remainingSeconds) : '—', profile.enabled ? 'Ativo' : 'Desativado'].forEach(value => {
        const cell = document.createElement('td'); cell.textContent = value; row.appendChild(cell);
      });
    body.appendChild(row);
  });
  if (!body.children.length) {
    const row = document.createElement('tr'), cell = document.createElement('td');
    cell.colSpan = 5; cell.textContent = 'Nenhuma conta tem regra de tempo. Selecione uma conta acima para começar.';
    row.appendChild(cell); body.appendChild(row);
  }
}
async function loadScreenTime(force = false) {
  if (screenLoading || screenBusy) return;
  screenLoading = true;
  screenElement('refresh').disabled = true;
  try {
    const data = await screenApi('/api/screen-time');
    const previousSid = screenElement('account').value;
    screenData = data;
    const select = screenElement('account');
    const eligibleAccounts = data.accounts.filter(account => account.eligible);
    select.replaceChildren();
    eligibleAccounts.forEach(account => {
      const option = document.createElement('option');
      option.value = account.sid;
      option.textContent = account.name;

      select.appendChild(option);
    });
    if (eligibleAccounts.some(a => a.sid === previousSid)) select.value = previousSid;
    else select.value = eligibleAccounts[0]?.sid || '';
    if (!eligibleAccounts.length) {
      const option = document.createElement('option'); option.value = ''; option.textContent = 'Nenhuma conta padrão habilitada encontrada'; select.appendChild(option);
    }
    screenElement('message').textContent = data.error || 'Contas atualizadas. Escolha quem será controlado e salve o limite.';
    screenElement('message').classList.toggle('screen-error', !!data.error);
    screenRenderSelection(force || !screenDirty || select.value !== previousSid);
    screenRenderTable();
  } catch (error) {
    screenElement('message').textContent = error.message;
    screenElement('message').classList.add('screen-error');
    screenElement('save').disabled = true;
  } finally { screenLoading = false; screenElement('refresh').disabled = false; }
}
screenElement('account').addEventListener('change', () => screenRenderSelection(true));
screenElement('form').addEventListener('input', () => { screenDirty = true; });
screenElement('refresh').addEventListener('click', () => loadScreenTime());
screenElement('form').addEventListener('submit', event => {
  event.preventDefault();
  const account = screenData?.accounts.find(a => a.sid === screenElement('account').value);
  if (!account?.eligible) return;
  screenPending = {
    userSid: account.sid, dailyMinutes: Number(screenElement('minutes').value),
    bonusMinutes: Number(screenElement('bonus').value), enabled: screenElement('enabled').checked
  };
  screenElement('auth-summary').textContent = (screenPending.enabled ? 'Aplicar ' + screenPending.dailyMinutes + ' minutos por dia a ' : 'Desativar o controle de ') + account.name + '. As outras contas serão preservadas.';
  screenElement('auth-error').textContent = '';
  screenElement('auth').showModal();
  screenElement('auth-submit').focus();
});
screenElement('auth-cancel').addEventListener('click', () => { if (!screenBusy) screenElement('auth').close(); });
screenElement('auth').addEventListener('cancel', event => { if (screenBusy) event.preventDefault(); });
screenElement('auth').addEventListener('close', () => { screenPending = null; });
screenElement('auth-form').addEventListener('submit', async event => {
  event.preventDefault();
  if (!screenPending || screenBusy) return;
  screenBusy = true;
  screenElement('auth-submit').disabled = true;
  screenElement('auth-cancel').disabled = true;
  screenElement('auth-error').textContent = '';
  try {
    const payload = { ...screenPending };
    const saving = screenApi('/api/screen-time/policy', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
      await saving;
    screenElement('auth').close();
    screenDirty = false;
    screenElement('message').textContent = 'Configurações salvas para a conta selecionada.';
  } catch (error) { screenElement('auth-error').textContent = error.message; }
  finally {
      screenElement('auth-submit').disabled = false; screenElement('auth-cancel').disabled = false;
    screenBusy = false;
  }
  if (!screenElement('auth').open) {
    await loadScreenTime(true);
    if (!screenData?.error) screenElement('message').textContent = 'Configurações salvas para a conta selecionada.';
  }
});
setInterval(() => {
  if (document.getElementById('view-screen-time').classList.contains('active') && !screenElement('auth').open) loadScreenTime();
}, 5000);
if (location.hash === '#screen-time') {
  document.querySelector('.sidebar nav a[data-view="screen-time"]').click();
}

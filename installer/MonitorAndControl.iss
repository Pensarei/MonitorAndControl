#ifndef PayloadDir
  #error PayloadDir must point to the verified publish folder
#endif
#ifndef AppVersion
  #define AppVersion "1.6.2"
#endif

[Setup]
AppId={{E31772E5-7E6D-4AC3-BA44-952E88EC624C}
AppName=Monitor & Control
AppVersion={#AppVersion}
AppPublisher=Monitor & Control contributors
AppPublisherURL=https://github.com/geogengames-hue/MonitorAndControl
DefaultDirName={autopf}\DeviceMon
DefaultGroupName=Monitor & Control
PrivilegesRequired=admin
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
MinVersion=10.0
DisableDirPage=yes
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=MonitorAndControl-Setup-{#AppVersion}-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\DeviceMon.exe
SetupLogging=yes
VersionInfoDescription=Monitor & Control Windows installer
VersionInfoCompany=Monitor & Control contributors
VersionInfoVersion={#AppVersion}
VersionInfoProductName=Monitor & Control

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "appsettings.json,*.pdb,*.ps1,*.log"
Source: "{#PayloadDir}\appsettings.json"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Abrir painel"; Filename: "http://localhost:5000"
Name: "{group}\Desinstalar Monitor & Control"; Filename: "{uninstallexe}"

[Code]
var StoppedExistingService: Boolean; InstallCompleted: Boolean;
function ServiceObject: Variant;
var Locator: Variant;
begin
  Locator := CreateOleObject('WbemScripting.SWbemLocator');
  Result := Locator.ConnectServer('', 'root\CIMV2');
end;

function ServiceState: String;
var Services, Rows, Row: Variant;
begin
  Result := 'absent';
  Services := ServiceObject;
  Rows := Services.ExecQuery('SELECT State FROM Win32_Service WHERE Name="GameHost"');
  if Rows.Count > 0 then begin
    Row := Rows.ItemIndex(0);
    Result := Row.State;
  end;
end;

procedure RunChecked(const FileName, Params: String);
var Code: Integer;
begin
  if not Exec(FileName, Params, '', SW_HIDE, ewWaitUntilTerminated, Code) then
    RaiseException('Falha ao executar: ' + FileName);
  if Code <> 0 then
    RaiseException('Operacao falhou (codigo ' + IntToStr(Code) + '): ' + FileName);
end;

procedure StopWatchdog;
var I: Integer; State: String;
begin
  State := ServiceState;
  if (State = 'absent') or (State = 'Stopped') then exit;
  RunChecked(ExpandConstant('{sys}\sc.exe'), 'stop GameHost');
  for I := 1 to 30 do begin
    Sleep(1000);
    if ServiceState = 'Stopped' then exit;
  end;
  RaiseException('O servico GameHost nao parou. Nenhum arquivo sera substituido.');
end;

procedure StopInstalledProcesses;
var Services, Rows, Row, Remaining: Variant; I, Attempt: Integer; Path, Identity: String;
begin
  Services := ServiceObject;
  Rows := Services.ExecQuery(
    'SELECT ExecutablePath,Name,ProcessId,CreationDate FROM Win32_Process WHERE Name="DeviceMon.exe" OR Name="PopupHost.exe" OR Name="UpdateAgent.exe"');
  for I := 0 to Rows.Count - 1 do begin
    Row := Rows.ItemIndex(I);
    if VarIsNull(Row.ExecutablePath) then
      RaiseException('Nao foi possivel identificar o processo ' + IntToStr(Row.ProcessId) + '. Feche o aplicativo e tente novamente.');
    Path := Row.ExecutablePath;
    if CompareText(ExtractFileDir(Path), ExpandConstant('{app}')) <> 0 then begin
      if MsgBox('Existe outra copia em execucao: ' + Path + #13#10 +
        'Deseja fechar esta copia tambem para concluir?', mbConfirmation, MB_YESNO) <> IDYES then
        RaiseException('Operacao cancelada. Feche a copia em execucao e tente novamente.');
    end;
    Identity := Row.CreationDate;
    Remaining := Services.ExecQuery('SELECT * FROM Win32_Process WHERE ProcessId=' + IntToStr(Row.ProcessId));
    if Remaining.Count > 0 then begin
      Row := Remaining.ItemIndex(0);
      if (String(Row.CreationDate) = Identity) and
         (CompareText(String(Row.ExecutablePath), Path) = 0) then begin
        if Row.Terminate(0) <> 0 then
          RaiseException('Nao foi possivel fechar ' + Path);
        for Attempt := 1 to 60 do begin
          Sleep(250);
          Remaining := Services.ExecQuery('SELECT CreationDate FROM Win32_Process WHERE ProcessId=' + IntToStr(Row.ProcessId));
          if Remaining.Count = 0 then break;
          if String(Remaining.ItemIndex(0).CreationDate) <> Identity then break;
        end;
        if Attempt >= 60 then
          RaiseException('O processo ainda esta encerrando: ' + Path + '. Tente novamente.');
      end;
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  try
    if (ServiceState <> 'absent') or FileExists(ExpandConstant('{app}\DeviceMon.exe')) then begin
      if WizardSilent then begin
        Result := 'Atualizacao exige confirmacao interativa para interromper o controle.';
        exit;
      end;
      if MsgBox('Para atualizar, o controle sera interrompido e os componentes desta instalacao serao fechados. Continuar?',
        mbConfirmation, MB_YESNO) <> IDYES then begin
        Result := 'Atualizacao cancelada.';
        exit;
      end;
      StopWatchdog;
      StoppedExistingService := ServiceState = 'Stopped';
      StopInstalledProcesses;
    end;
  except
    Result := GetExceptionMessage;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var I: Integer;
begin
  if CurStep = ssPostInstall then begin
    RunChecked(ExpandConstant('{app}\GameHost.exe'), '--install --no-elevate');
    for I := 1 to 30 do begin
      if ServiceState = 'Running' then break;
      Sleep(1000);
    end;
    if ServiceState <> 'Running' then
      RaiseException('Arquivos instalados, mas GameHost nao iniciou. Consulte o log; a protecao nao esta ativa.');
    InstallCompleted := True;
    if not WizardSilent then
      MsgBox('Instalacao concluida. Abra localhost:5000 e configure a senha administrativa. Use conta Windows padrao para o usuario controlado. Dados e regras existentes foram preservados.',
        mbInformation, MB_OK);
  end;
end;

procedure CleanupAutoStart;
var Profiles: TArrayOfString; I: Integer; Entry: String; Key: String;
begin
  if RegGetSubkeyNames(HKEY_USERS, '', Profiles) then
    for I := 0 to GetArrayLength(Profiles) - 1 do begin
      Key := Profiles[I] + '\Software\Microsoft\Windows\CurrentVersion\Run';
      if RegQueryStringValue(HKEY_USERS, Key, 'DeviceMon', Entry) then
        if (CompareText(Entry, '"' + ExpandConstant('{app}\DeviceMon.exe') + '" --autostart') = 0) or
           (CompareText(Entry, '"' + ExpandConstant('{app}\DeviceMon.exe') + '"') = 0) then
          if not RegDeleteValue(HKEY_USERS, Key, 'DeviceMon') then
            Log('Nao foi possivel remover inicio automatico do perfil: ' + Profiles[I]);
    end;
end;
function InitializeUninstall: Boolean;
begin
  Result := False;
  if UninstallSilent then begin
    MsgBox('Use a desinstalacao interativa para confirmar a interrupcao do controle.', mbError, MB_OK);
    exit;
  end;
  if MsgBox('Remover o controle deste PC? O monitor sera encerrado. Historico, senha e configuracao serao preservados.',
    mbConfirmation, MB_YESNO) <> IDYES then exit;
  try
    StopWatchdog;
    StopInstalledProcesses;
    RunChecked(ExpandConstant('{app}\GameHost.exe'), '--uninstall');
    if ServiceState <> 'absent' then
      RaiseException('GameHost ainda existe. Remocao cancelada para preservar os arquivos.');
    CleanupAutoStart;
    Result := True;
  except
    MsgBox(GetExceptionMessage, mbError, MB_OK);
  end;
end;

procedure DeinitializeSetup;
var Code: Integer;
begin
  if StoppedExistingService and not InstallCompleted then begin
    try
      if ServiceState = 'Stopped' then
        if not Exec(ExpandConstant('{sys}\sc.exe'), 'start GameHost', '', SW_HIDE, ewWaitUntilTerminated, Code) then
          Log('Nao foi possivel solicitar recuperacao do servico apos instalacao interrompida.');
    except
      Log('Falha ao recuperar servico: ' + GetExceptionMessage);
    end;
  end;
end;
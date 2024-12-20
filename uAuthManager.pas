unit uAuthManager;

interface

uses
  Windows, TlHelp32, SysUtils, Classes, uUtils, uLeagueHandler, uSessionData;

type
  TAuthManager = class(TThread)
  private
    fPort, fRiotPort: Integer;
    fAuthToken, fRiotAuthToken, fStatus: string;
    fLeagueHandler: TLeagueHandler;

    procedure AuthLeagueClient(pProccessId: Integer);
    procedure OnLeagueClientClosed(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ResetAuth;

    property Port: Integer read fPort;
    property AuthToken: string read fAuthToken;
    property RiotPort: Integer read fRiotPort;
    property RiotAuthToken: string read fRiotAuthToken;
    property Status: string read fStatus write fStatus;
    property LeagueHandler: TLeagueHandler read fLeagueHandler write fLeagueHandler;
  end;

implementation

{ TAuthManager }

constructor TAuthManager.Create;
begin
  inherited Create(False);

  fStatus := 'None';

  fLeagueHandler := TLeagueHandler.Create;
  fLeagueHandler.OnLeagueClientClosed := OnLeagueClientClosed;
end;

destructor TAuthManager.Destroy;
begin
  if Assigned(fLeagueHandler) then
  begin
    fLeagueHandler.OnDataUpdate := nil;
    fLeagueHandler.Terminate;
    fLeagueHandler.WaitFor;
    FreeAndNil(fLeagueHandler);
  end;

  inherited Destroy;
end;

procedure TAuthManager.Execute;
var
  vClientProcessId: Integer;
begin
  inherited;

  while not Terminated do
  begin
    if fLeagueHandler.ClientClosed then
    begin
      vClientProcessId := GetProcessIDByName('LeagueClientUx.exe');

      if vClientProcessId <> 0 then
        AuthLeagueClient(vClientProcessId);
    end;

    if (fPort > 0) and (fAuthToken <> '') and (fRiotPort > 0) and (fRiotAuthToken <> '') and (fLeagueHandler.ClientClosed) then
    begin
      fLeagueHandler.SetAuthData(fPort, fRiotPort, fAuthToken, fRiotAuthToken);
      fLeagueHandler.ClientClosed := False;
    end;

    Sleep(1000);
  end;
end;

procedure TAuthManager.AuthLeagueClient(pProccessId: Integer);
var
  vSecurityAttr: TSecurityAttributes;
  vStartupInfo: TStartupInfo;
  vProcessInfo: TProcessInformation;
  vStdOutPipeRead, StdOutPipeWrite: THandle;
  vStartupSuccess: Boolean;
  vBuffer: array[0..255] of AnsiChar;
  vBytesRead: DWORD;
  vWMICCommand: PChar;
  vWMICReturn: string;
begin
  vSecurityAttr.nLength := SizeOf(TSecurityAttributes);
  vSecurityAttr.bInheritHandle := True;
  vSecurityAttr.lpSecurityDescriptor := nil;

  vStartupSuccess := False;

  try
    if CreatePipe(vStdOutPipeRead, StdOutPipeWrite, @vSecurityAttr, 0) then
    begin
      FillChar(vStartupInfo, SizeOf(TStartupInfo), 0);
      vStartupInfo.cb := SizeOf(TStartupInfo);
      vStartupInfo.hStdOutput := StdOutPipeWrite;
      vStartupInfo.hStdError := StdOutPipeWrite;
      vStartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      vStartupInfo.wShowWindow := SW_HIDE;

      vWMICCommand := PChar('wmic process where ProcessId=' + IntToStr(pProccessId) + ' get Commandline');

      vStartupSuccess := CreateProcess(nil, vWMICCommand, nil, nil, True, CREATE_NO_WINDOW, nil, nil, vStartupInfo, vProcessInfo);

      CloseHandle(StdOutPipeWrite);

      if vStartupSuccess then
      begin
        repeat
          if ReadFile(vStdOutPipeRead, vBuffer, Length(vBuffer), vBytesRead, nil) then
          begin
            if vBytesRead > 0 then
              vWMICReturn := vWMICReturn + string(vBuffer);
          end
          else
            Break;
        until vBytesRead = 0;

        fPort := StrToInt(ExtractRegexText(vWMICReturn, '--app-port'));
        fAuthToken := ExtractRegexText(vWMICReturn, '--remoting-auth-token');
        fRiotPort := StrToInt(ExtractRegexText(vWMICReturn, '--riotclient-app-port'));
        fRiotAuthToken := ExtractRegexText(vWMICReturn, '--riotclient-auth-token');
      end;

    end;
  finally
    if vStartupSuccess then
    begin
      CloseHandle(vProcessInfo.hThread);
      CloseHandle(vProcessInfo.hProcess);
    end;

    CloseHandle(vStdOutPipeRead);
  end;
end;

procedure TAuthManager.OnLeagueClientClosed(Sender: TObject);
begin
  fLeagueHandler.ClientClosed := True;
  fLeagueHandler.SummonerDataLoaded := False;
  SessionData.ResetLobbyParticipants;
  ResetAuth;
end;

procedure TAuthManager.ResetAuth;
begin
  fPort := 0;
  fAuthToken := '';
  fRiotPort := 0;
  fRiotAuthToken := '';
end;

end.


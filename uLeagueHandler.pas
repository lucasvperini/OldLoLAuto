unit uLeagueHandler;

interface

uses
  System.Classes, SysUtils, StrUtils, System.JSON, uSessionData, DateUtils, System.Generics.Collections, uUtils, System.Net.HttpClientComponent,
  System.Net.HttpClient, System.Net.URLClient, System.NetEncoding;

type
  TLeagueHandler = class(TThread)
  private
    fNetHTTPClient: TNetHTTPClient;
    fOnDataUpdate, fOnLeagueClientClosed: TNotifyEvent;
    fBaseURL, fRiotBaseURL, fStatus, fLastStatus: string;
    fAuthToken, fRiotAuthToken: string;
    fSummonerDataLoaded: Boolean;
    fPickedChamp: Boolean;
    fLockedChamp: Boolean;
    fPickedBan: Boolean;
    fLockedBan: Boolean;
    fPickedSpell1: Boolean;
    fPickedSpell2: Boolean;
    fSentChatMessages: Boolean;
    fLastActStartTime: Double;
    fChampSelectStart: Double;
    fLastActId: string;
    fLastChatRoom: string;
    fClientClosed: Boolean;
    fGotLobbyParticipants: Boolean;

    function GetClientStatus: string;

    procedure LoadSummonerData;
    procedure GetSummonerIDandName;
    procedure GetSummonerChampions;
    procedure GetSummonerSpells;
    procedure HandleSummonerSpells;

    procedure HandleReadyCheck;
    procedure HandleChampSelect;
    procedure HandlePickOrderSwap;
    procedure HandleChampSelectActions(pChampSelectInfo: TJSONObject; pCellID: string);
    procedure HandlePickAction(const pActId: string; pActIsInProgress: Boolean; pChampSelectInfo: TJSONObject);
    procedure HandleBanAction(const pActId: string; pActIsInProgress: Boolean; pChampSelectInfo: TJSONObject);
    procedure HoverChampion(const pActId, pChampionId, pActType: string);
    procedure LockChampion(const pActId, pChampionId, pActType: string);
    procedure HandleChampSelectChat(const pChatId: string);
    procedure HandleChampSelectSpell(const pSpellId: string; pSpellSlot: Integer);

    procedure SendChatMessage(const pChatId, pMessage: string);
    procedure MarkPhaseStart(const pActId: string);
    procedure ResetChampSelectActions;

    procedure GetLobbyParticipants;

    procedure HandleNetHTTPClientValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetAuthData(pPort, pRiotPort: Integer; const pAuthToken, pRiotAuthToken: string);
    procedure DodgeQueue;

    property Status: string read fStatus;
    property ClientClosed: Boolean read fClientClosed write fClientClosed;
    property SummonerDataLoaded: Boolean read fSummonerDataLoaded write fSummonerDataLoaded;
    property OnDataUpdate: TNotifyEvent read fOnDataUpdate write fOnDataUpdate;
    property OnLeagueClientClosed: TNotifyEvent read fOnLeagueClientClosed write fOnLeagueClientClosed;
  end;

var
  LeagueHandler: TLeagueHandler;

implementation

{ TLeagueHandler }

constructor TLeagueHandler.Create;
begin
  inherited Create(False);

  fNetHTTPClient := TNetHTTPClient.Create(nil);
  fNetHTTPClient.ConnectionTimeout := 1000;
  fNetHTTPClient.ResponseTimeout := 1000;
  fNetHTTPClient.OnValidateServerCertificate := HandleNetHTTPClientValidateServerCertificate;

  fStatus := 'None';
  fLastStatus := 'None';
  fSummonerDataLoaded := False;
  fClientClosed := True;
  fLastActId := '';
  fPickedChamp := False;
  fLockedChamp := False;
  fPickedBan := False;
  fLockedBan := False;
  fPickedSpell1 := False;
  fPickedSpell2 := False;
  fSentChatMessages := False;
  fChampSelectStart := Now.ToUnix();
  fGotLobbyParticipants := False;
end;

destructor TLeagueHandler.Destroy;
begin
  FreeAndNil(fNetHTTPClient);
  inherited Destroy;
end;

procedure TLeagueHandler.DodgeQueue;
var
  vResponse: IHTTPResponse;
begin
  vResponse := fNetHTTPClient.Post(fBaseURL + '/lol-login/v1/session/invoke?destination=lcdsServiceProxy&method=call&args=["","teambuilder-draft","quitV2",""]', TStream(nil));

  if vResponse.StatusCode = 200 then
    SessionData.ActionsLogger.AddLog('Dodge done successfully.');
end;

procedure TLeagueHandler.Execute;
begin
  inherited;
  while not Terminated do
  begin
    try
      if (not fClientClosed) then
      begin
        if fSummonerDataLoaded then
        begin
          fLastStatus := fStatus;
          fStatus := GetClientStatus;
//        fGamemode := GetCurrentGamemode;

          case AnsiIndexStr(fStatus, ['Lobby', 'Matchmaking', 'ReadyCheck', 'ChampSelect', 'InProgress', 'WaitingForStats', 'PreEndOfGame', 'EndOfGame']) of
            0: //Lobby
              Sleep(500);
            1: //Matchmaking
              Sleep(500);
            2: //ReadyCheck
              begin
                HandleReadyCheck;
                Sleep(500);
              end;
            3: //ChampSelect
              begin
                HandleChampSelect;
                HandlePickOrderSwap;

                Sleep(500);
              end;
            4: //InProgress
              Sleep(500);
            5: //WaitingForStats
              Sleep(500);
            6: //PreEndOfGame
              Sleep(500);
            7: //EndOfGame
              Sleep(500);
          else
            Sleep(500);
          end;

          if (fLastStatus = 'ChampSelect') and (fStatus <> 'ChampSelect') then
            ResetChampSelectActions;

        end
        else
          LoadSummonerData;
      end;

      Synchronize(
        procedure
        begin
          if Assigned(fOnDataUpdate) then
            fOnDataUpdate(Self);
        end);

      Sleep(500);
    except
      on E: Exception do //On a exception, tell the AuthManager that the client is down
      begin
        SessionData.ActionsLogger.AddLog('Connection to the client lost. Trying to restore...');

        if Assigned(fOnLeagueClientClosed) then
          fOnLeagueClientClosed(Self);
      end;
    end;
  end;
end;

procedure TLeagueHandler.HandleNetHTTPClientValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);
begin
  Accepted := True;
end;

procedure TLeagueHandler.SetAuthData(pPort, pRiotPort: Integer; const pAuthToken, pRiotAuthToken: string);
begin
  fBaseURL := 'https://127.0.0.1:' + IntToStr(pPort);
  fAuthToken := pAuthToken;
  fRiotBaseURL := 'https://127.0.0.1:' + IntToStr(pRiotPort);
  fRiotAuthToken := pRiotAuthToken;

  fNetHTTPClient.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64.Encode('riot:' + fAuthToken);
end;

function TLeagueHandler.GetClientStatus: string;
var
  vResponse: IHTTPResponse;
begin
  vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-gameflow/v1/gameflow-phase');

  if vResponse.StatusCode = 200 then
    Result := Copy(vResponse.ContentAsString, 2, Length(vResponse.ContentAsString) - 2)
  else
    Result := '';
end;

procedure TLeagueHandler.GetLobbyParticipants;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONObject;
  vParticipantsArray: TJSONArray;
  vCount: Integer;
begin
  vResponseJSON := nil;

  try
    //Change the auth header to Riot token;
    fNetHTTPClient.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64.Encode('riot:' + fRiotAuthToken);

    vResponse := fNetHTTPClient.Get(fRiotBaseURL + '/chat/v5/participants/champ-select');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0) as TJSONObject;

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONObject) then
    begin
      vParticipantsArray := vResponseJSON.GetValue('participants') as TJSONArray;

      for vCount := 0 to vParticipantsArray.Count - 1 do
      begin
        if vParticipantsArray.Items[vCount] is TJSONObject then
        begin
          SessionData.LobbyParticipants[vCount] := (vParticipantsArray.Items[vCount] as TJSONObject).GetValue('game_name').Value + '#' + (vParticipantsArray.Items[vCount] as TJSONObject).GetValue('game_tag').Value;
        end;
      end;
    end;

    fGotLobbyParticipants := True;
  finally
    //Get back to the old client token;
    SessionData.ActionsLogger.AddLog('Lobby participants successfully recovered.');
    fNetHTTPClient.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64.Encode('riot:' + fAuthToken);
    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.LoadSummonerData;
begin
  SessionData.ResetSettings;
  GetSummonerIDandName;
  GetSummonerChampions;
  GetSummonerSpells;

  //TODO: Test avaliable champions from a newly created account, maybe it's 0 on tutorial or so, pbbly needs a workaround;
  if (SessionData.SummonerID <> '') and (SessionData.AvaliableSpells.Count > 0) and (SessionData.AvaliableChampions.Count > 0) then
  begin
    fSummonerDataLoaded := True;
    SessionData.ActionsLogger.AddLog('Client connected and information loaded successfully.');
  end;
end;

procedure TLeagueHandler.HandleReadyCheck;
var
  vResponse: IHTTPResponse;
begin
  if (not SessionData.AutoAcceptQueue) then
    Exit;

  SessionData.ActionsLogger.AddLog('Match found. Trying to accept.');

  vResponse := fNetHTTPClient.Post(fBaseURL + '/lol-matchmaking/v1/ready-check/accept', TStream(nil));

  if vResponse.StatusCode = 200 then
    SessionData.ActionsLogger.AddLog('Match accepted automatically.');
end;

procedure TLeagueHandler.HandleChampSelect;
var
  vResponse: IHTTPResponse;
  vCurrentChatRoom, vPlayerCellID: string;
  vResponseJSON, vChatDetailsObj: TJSONObject;
  vCurrentTime: Double;
begin
  vResponseJSON := nil;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-champ-select/v1/session');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0) as TJSONObject;
    vChatDetailsObj := vResponseJSON.GetValue('chatDetails') as TJSONObject;
    vCurrentChatRoom := vChatDetailsObj.GetValue('multiUserChatId').Value;
    fLastChatRoom := vCurrentChatRoom;

    if not fGotLobbyParticipants then
    begin
      vCurrentTime := Now.ToUnix;
      if (Length(SessionData.LobbyParticipantsList) = 0) and ((vCurrentTime - 2) > fChampSelectStart) then
      begin
        GetLobbyParticipants;
      end;
    end;

    if (fPickedChamp and fLockedChamp and fPickedBan and fLockedBan and fPickedSpell1 and fPickedSpell2 and fSentChatMessages) then
    begin
      Sleep(500);
    end
    else
    begin
      if (not SessionData.ShouldPickChampion) and (not fPickedChamp) and (not fLockedChamp) then
      begin
        fPickedChamp := True;
        fLockedChamp := True;
        SessionData.ActionsLogger.AddLog('Seleção automática de campeão desabilitada, ignorando...');
      end;

      if (not SessionData.ShouldBanChampion) and (not fPickedBan) and (not fLockedBan) then
      begin
        fPickedBan := True;
        fLockedBan := True;
        SessionData.ActionsLogger.AddLog('Banimento automático desabilitado, ignorando...');
      end;

      if (not SessionData.ShouldSelectSpell1) and (not fPickedSpell1) then
      begin
        fPickedSpell1 := True;
        SessionData.ActionsLogger.AddLog('Seleção automática de feitiço (D) desabilitada, ignorando...');
      end;

      if (not SessionData.ShouldSelectSpell2) and (not fPickedSpell2) then
      begin
        fPickedSpell2 := True;
        SessionData.ActionsLogger.AddLog('Seleção automática de feitiço (F) desabilitada, ignorando...');
      end;

      if (not SessionData.ShouldSendChatMessage) and (not fSentChatMessages) then
      begin
        fSentChatMessages := True;
        SessionData.ActionsLogger.AddLog('Envio automático de mensagem desabilitado, ignorando...');
      end;

      if (not fSentChatMessages) and (SessionData.ChatMessage <> '') then
        HandleChampSelectChat(vCurrentChatRoom);

      if (not fPickedChamp) or (not fLockedChamp) or (not fPickedBan) or (not fLockedBan) then
      begin
        vPlayerCellID := vResponseJSON.GetValue('localPlayerCellId').Value;
        HandleChampSelectActions(vResponseJSON, vPlayerCellID);
      end;

      if not fPickedSpell1 then
        HandleChampSelectSpell(SessionData.Spell1, 0);

      if not fPickedSpell2 then
        HandleChampSelectSpell(SessionData.Spell2, 1);
    end;
  finally
    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.HandlePickOrderSwap;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONObject;
  vSwapId: Integer;
  vRequestURI: string;
begin
  vResponseJSON := nil;

  if (not SessionData.AutoTradePick) or (SessionData.ShouldPickChampion and fLockedChamp) then
    Exit;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-champ-select/v1/ongoing-swap');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0) as TJSONObject;

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONObject) and (vResponse.StatusCode = 200) then
    begin
      if (not StrToBool(vResponseJSON.GetValue('initiatedByLocalPlayer').Value)) then
      begin
        if TryStrToInt(vResponseJSON.GetValue('id').Value, vSwapId) then
        begin
          vRequestURI := '/lol-champ-select/v1/session/swaps/' + IntToStr(vSwapId) + '/accept';
          vResponse := fNetHTTPClient.Post(fBaseURL + vRequestURI, TStream(nil));

          vRequestURI := '/lol-champ-select/v1/ongoing-swap/' + IntToStr(vSwapId) + '/clear';
          vResponse := fNetHTTPClient.Post(fBaseURL + vRequestURI, TStream(nil));
        end;
      end;
    end;
  finally
    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.HandleChampSelectActions(pChampSelectInfo: TJSONObject; pCellID: string);
var
  vActorCellId, vActCompleted, vActType, vActID: string;
  vActInProgress: Boolean;
  vCurrentAction: TJSONObject;
  vActionsInfo, vCurrentActionArray: TJSONArray;
  vCount, vCount2: Integer;
begin
  vActionsInfo := pChampSelectInfo.GetValue('actions') as TJSONArray;

  for vCount := 0 to vActionsInfo.Count - 1 do
  begin
    vCurrentActionArray := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vActionsInfo.Items[vCount].ToString), 0) as TJSONArray;

    if Assigned(vCurrentActionArray) then
    begin
      for vCount2 := 0 to vCurrentActionArray.Count - 1 do
      begin
        vCurrentAction := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vCurrentActionArray.Items[vCount2].ToString), 0) as TJSONObject;

        if Assigned(vCurrentAction) then
        begin
          vActorCellId := vCurrentAction.GetValue('actorCellId').Value;
          vActCompleted := vCurrentAction.GetValue('completed').Value;
          vActType := vCurrentAction.GetValue('type').Value;
          vActID := vCurrentAction.GetValue('id').Value;
          vActInProgress := StrToBool(vCurrentAction.GetValue('isInProgress').Value);

          vCurrentAction.Free;

          if (vActorCellId <> pCellID) or (StrToBool(vActCompleted)) then
            Continue;

          if (vActType = 'pick') then
          begin
            HandlePickAction(vActID, vActInProgress, pChampSelectInfo);
          end
          else if (vActType = 'ban') then
          begin
            HandleBanAction(vActID, vActInProgress, pChampSelectInfo);
          end;
        end;
      end;
    end;
    vCurrentActionArray.Free;
  end;
end;

procedure TLeagueHandler.HandlePickAction(const pActId: string; pActIsInProgress: boolean; pChampSelectInfo: TJSONObject);
var
  vChampSelectPhase: string;
  vChampTimer: TJSONObject;
  vCurrentTime: Double;
begin
  if not fPickedChamp then
  begin
    vChampTimer := pChampSelectInfo.GetValue('timer') as TJSONObject;
    vChampSelectPhase := vChampTimer.GetValue('phase').Value;
    vCurrentTime := Now.ToUnix;

    if ((vCurrentTime - 5) > fChampSelectStart) or (vChampSelectPhase <> 'PLANNING') or (SessionData.ShouldInstantHoverChampion) then
      HoverChampion(pActId, SessionData.ChampionPick, 'pick');
  end;

  if pActIsInProgress then
  begin
    MarkPhaseStart(pActId);

    if not fLockedChamp then
    begin
      LockChampion(pActId, SessionData.ChampionPick, 'pick');
    end;
  end;
end;

procedure TLeagueHandler.HandleBanAction(const pActId: string; pActIsInProgress: boolean; pChampSelectInfo: TJSONObject);
var
  vChampSelectPhase: string;
  vChampTimer: TJSONObject;
begin
  vChampTimer := pChampSelectInfo.GetValue('timer') as TJSONObject;
  vChampSelectPhase := vChampTimer.GetValue('phase').Value;

  if (pActIsInProgress) and (vChampSelectPhase <> 'PLANNING') then
  begin
    MarkPhaseStart(pActId);

    if not fPickedBan then
      HoverChampion(pActId, SessionData.ChampionBan, 'ban');

    if not fLockedBan then
      LockChampion(pActId, SessionData.ChampionBan, 'ban');
  end;
end;

procedure TLeagueHandler.HoverChampion(const pActId, pChampionId, pActType: string);
var
  vResponse: IHTTPResponse;
  vRequestContent: TStringStream;
  vChampionName: string;
begin
  vRequestContent := nil;
  vChampionName := 'None';

  try
    vRequestContent := TStringStream.Create('{"championId":"' + pChampionId + '"}', TEncoding.UTF8);
    vResponse := fNetHTTPClient.Patch(fBaseURL + '/lol-champ-select/v1/session/actions/' + pActId, vRequestContent);

    vChampionName := GetChampionNameByID(StrToInt(pChampionId));

    if vResponse.StatusCode = 204 then
    begin
      if pActType = 'pick' then
      begin
        fPickedChamp := True;
        SessionData.ActionsLogger.AddLog('Campeão ' + vChampionName + ' mostrado para seleção automaticamente.');
      end
      else if pActType = 'ban' then
      begin
        fPickedBan := True;
        SessionData.ActionsLogger.AddLog('Campeão ' + vChampionName + ' mostrado para banimento automaticamente.');
      end;
    end
    else
    begin
      if pActType = 'pick' then
        SessionData.ActionsLogger.AddLog('Falha ao mostrar a seleção do campeão ' + vChampionName + ' automaticamente.')
      else if pActType = 'ban' then
        SessionData.ActionsLogger.AddLog('Falha ao mostrar o banimento do campeão ' + vChampionName + ' automaticamente.')
    end;

  finally
    vRequestContent.Free;
  end;
end;

procedure TLeagueHandler.LockChampion(const pActId, pChampionId, pActType: string);
var
  vResponse: IHTTPResponse;
  vRequestContent: TStringStream;
  vChampionName: string;
begin
  vRequestContent := nil;
  vChampionName := 'None';

  try
    vRequestContent := TStringStream.Create('{"completed":true, "championId":"' + pChampionId + '"}', TEncoding.UTF8);
    vResponse := fNetHTTPClient.Patch(fBaseURL + '/lol-champ-select/v1/session/actions/' + pActId, vRequestContent);

    vChampionName := GetChampionNameByID(StrToInt(pChampionId));

    if vResponse.StatusCode = 204 then
    begin
      if pActType = 'pick' then
      begin
        fLockedChamp := True;
        SessionData.ActionsLogger.AddLog('Campeão ' + vChampionName + ' selecionado automaticamente.');
      end
      else if pActType = 'ban' then
      begin
        fLockedBan := True;
        SessionData.ActionsLogger.AddLog('Campeão ' + vChampionName + ' banido automaticamente.');
      end;
    end
    else
    begin
      if pActType = 'pick' then
        SessionData.ActionsLogger.AddLog('Falha ao selecionar campeão ' + vChampionName + ' automaticamente.')
      else if pActType = 'ban' then
        SessionData.ActionsLogger.AddLog('Falha ao banir campeão ' + vChampionName + ' automaticamente.')
    end;
  finally
    vRequestContent.Free;
  end;
end;

procedure TLeagueHandler.HandleChampSelectChat(const pChatId: string);
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONValue;
  vChatArray: TJSONArray;
  vCount: Integer;
  vChatId: string;
  vCurrentTime: Double;
begin
  vResponseJSON := nil;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-chat/v1/conversations');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0);

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONArray) then
    begin
      vChatArray := vResponseJSON as TJSONArray;

      for vCount := 0 to vChatArray.Count - 1 do
      begin
        if vChatArray.Items[vCount] is TJSONObject then
        begin
          vChatId := (vChatArray.Items[vCount] as TJSONObject).GetValue('id').Value;
          vCurrentTime := Now.ToUnix;

          if ((vCurrentTime - 1) > fChampSelectStart) and (fLastChatRoom = ExtractAtSignPrefix(vChatId)) then
          begin
            SendChatMessage(vChatId, SessionData.ChatMessage);
          end;
        end;
      end;
    end;

  finally
    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.SendChatMessage(const pChatId, pMessage: string);
var
  vResponse: IHTTPResponse;
  vAttempts: Integer;
  vTimeStamp: string;
  vRequestContent: TStringStream;
begin
  vAttempts := 0;
  vTimeStamp := FormatDateTime('yyyy-MM-ddTHH:mm:ssZ', Now);
  vRequestContent := nil;

  try
    while vAttempts < 3 do
    begin
      vRequestContent := TStringStream.Create('{"type":"chat", "fromId":"' + SessionData.CurrentChatId + '","fromSummonerId":"' + SessionData.SummonerID + '","isHistorical":false,"timestamp":"' + vTimeStamp + '","body":"' + pMessage + '"}', TEncoding.UTF8);
      vResponse := fNetHTTPClient.Post(fBaseURL + '/lol-chat/v1/conversations/' + pChatId + '/messages', vRequestContent);

      if vResponse.StatusCode = 200 then
      begin
        fSentChatMessages := True;
        SessionData.ActionsLogger.AddLog('Mensagem automática enviada com sucesso.');
        Break
      end
      else
      begin
        Sleep(500);
        Inc(vAttempts);
      end;
    end;
  finally
    vRequestContent.Free;
  end;
end;

procedure TLeagueHandler.HandleChampSelectSpell(const pSpellId: string; pSpellSlot: Integer);
var
  vResponse: IHTTPResponse;
  vRequestContent: TStringStream;
begin
  vRequestContent := nil;

  try
    if pSpellSlot = 0 then
    begin
      vRequestContent := TStringStream.Create('{"spell1Id":"' + pSpellId + '"}', TEncoding.UTF8);
      vResponse := fNetHTTPClient.Patch(fBaseURL + '/lol-champ-select/v1/session/my-selection', vRequestContent);

      if vResponse.StatusCode = 204 then
        fPickedSpell1 := True;
    end
    else if pSpellSlot = 1 then
    begin
      vRequestContent := TStringStream.Create('{"spell2Id":"' + pSpellId + '"}', TEncoding.UTF8);
      vResponse := fNetHTTPClient.Patch(fBaseURL + '/lol-champ-select/v1/session/my-selection', vRequestContent);

      if vResponse.StatusCode = 204 then
        fPickedSpell2 := True;
    end;
  finally
    vRequestContent.Free;
  end;
end;

procedure TLeagueHandler.MarkPhaseStart(const pActId: string);
begin
  if pActId <> fLastActId then
  begin
    fLastActId := pActId;
    fLastActStartTime := Now.ToUnix;
  end;
end;

procedure TLeagueHandler.ResetChampSelectActions;
begin
  try
    fPickedChamp := False;
    fLockedChamp := False;
    fPickedBan := False;
    fLockedBan := False;
    fPickedSpell1 := False;
    fPickedSpell2 := False;
    fSentChatMessages := False;
    fChampSelectStart := Now.ToUnix();
    fGotLobbyParticipants := False;
    SessionData.ResetLobbyParticipants;

    SessionData.ActionsLogger.AddLog('Seleção de campeões abandonada. Reiniciando parâmetros de seleção...');
  except
    on E: Exception do
      SessionData.ActionsLogger.AddLog('Falha ao reiniciar indicadores da seleção de campeões. (' + E.Message + ')');
  end;
end;

procedure TLeagueHandler.GetSummonerIDandName;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONValue;
begin
  vResponseJSON := nil;

  try
    SessionData.ActionsLogger.AddLog('Carregando informações do cliente...');
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-chat/v1/me');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0) as TJSONObject;
    SessionData.SummonerID := (vResponseJSON as TJSONObject).GetValue('summonerId').Value;
    SessionData.SummonerName := (vResponseJSON as TJSONObject).GetValue('gameName').Value;
    SessionData.CurrentChatId := (vResponseJSON as TJSONObject).GetValue('id').Value;
  finally
    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.GetSummonerChampions;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONValue;
  vDataArray: TJSONArray;
  vOwnership, vRental: TJSONObject;
  vCount: Integer;
begin
  vResponseJSON := nil;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-champions/v1/inventories/' + SessionData.SummonerID + '/champions-minimal');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString()), 0);

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONArray) then
    begin
      vDataArray := vResponseJSON as TJSONArray;

      for vCount := 1 to vDataArray.Count - 1 do
      begin
        if vDataArray.Items[vCount] is TJSONObject then
        begin
          vOwnership := (vDataArray.Items[vCount] as TJSONObject).GetValue('ownership') as TJSONObject;
          vRental := vOwnership.GetValue('rental') as TJSONObject;

          SessionData.AllChampions.Add(TChampionInfo.Create((vDataArray.Items[vCount] as TJSONObject).GetValue('name').Value, StrToInt((vDataArray.Items[vCount] as TJSONObject).GetValue('id').Value)));

          //Maybe there's even more ways to check this, because even if owned = false, the player may can use the champion with Riot acc, etc...
          //TODO: Check for some summoner ID of a Riot account to see what's different
          if StrToBool(vOwnership.GetValue('owned').Value) or StrToBool(vOwnership.GetValue('xboxGPReward').Value) or StrToBool(vRental.GetValue('rented').Value) then
            SessionData.AvaliableChampions.Add(TChampionInfo.Create((vDataArray.Items[vCount] as TJSONObject).GetValue('name').Value, StrToInt((vDataArray.Items[vCount] as TJSONObject).GetValue('id').Value)));
        end;
      end;
    end;
  finally
    if SessionData.AllChampions.Count > 0 then
      SessionData.ActionsLogger.AddLog('Lista de campeões carregada com sucesso. Total: ' + IntToStr(SessionData.AllChampions.Count) + '.')
    else
      SessionData.ActionsLogger.AddLog('Falha ao carregar lista total de campeões.');

    if SessionData.AvaliableChampions.Count > 0 then
      SessionData.ActionsLogger.AddLog('Lista de campeões disponíveis carregados com sucesso. Total: ' + IntToStr(SessionData.AvaliableChampions.Count) + '.')
    else
      SessionData.ActionsLogger.AddLog('Falha ao carregar lista disponível de campeões.');

    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.GetSummonerSpells;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONValue;
  vDataArray: TJSONArray;
  vCount, vSpellIDInt: Integer;
  vSpellID: string;
begin
  vResponseJSON := nil;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-collections/v1/inventories/' + SessionData.SummonerID + '/spells');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0);

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONObject) then
    begin
      if vResponseJSON.TryGetValue<TJSONArray>('spells', vDataArray) then
      begin
        for vCount := 0 to vDataArray.Count - 1 do
        begin
          vSpellID := vDataArray.Items[vCount].Value;

          if TryStrToInt(vSpellID, vSpellIDInt) then
            SessionData.AvaliableSpells.Add(TSummonerSpellsInfo.Create(vSpellIDInt, ''));
        end;

      end;
    end;

    HandleSummonerSpells;
  finally
    if SessionData.AvaliableSpells.Count > 0 then
      SessionData.ActionsLogger.AddLog('Lista de feitiços carregada com sucesso. Total: ' + IntToStr(SessionData.AvaliableSpells.Count) + '.')
    else
      SessionData.ActionsLogger.AddLog('Falha ao carregar lista de feitiços.');

    vResponseJSON.Free;
  end;
end;

procedure TLeagueHandler.HandleSummonerSpells;
var
  vResponse: IHTTPResponse;
  vResponseJSON: TJSONValue;
  vDataArray, vGamemodesArray: TJSONArray;
  vSpellIDInt, vCount, vCount2, vCount3: Integer;
begin
  vResponseJSON := nil;

  try
    vResponse := fNetHTTPClient.Get(fBaseURL + '/lol-game-data/assets/v1/summoner-spells.json');
    vResponseJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(vResponse.ContentAsString), 0);

    if Assigned(vResponseJSON) and (vResponseJSON is TJSONArray) then
    begin
      vDataArray := vResponseJSON as TJSONArray;

      for vCount := 0 to vDataArray.Count - 1 do
      begin
        if vDataArray.Items[vCount] is TJSONObject then
        begin
          for vCount2 := SessionData.AvaliableSpells.Count - 1 downto 0 do
          begin
            if TryStrToInt((vDataArray.Items[vCount] as TJSONObject).GetValue('id').Value, vSpellIDInt) then
            begin
              if SessionData.AvaliableSpells[vCount2].ID = vSpellIDInt then
              begin
                SessionData.AvaliableSpells[vCount2].Name := (vDataArray.Items[vCount] as TJSONObject).GetValue('name').Value;

                vGamemodesArray := (vDataArray.Items[vCount] as TJSONObject).GetValue('gameModes') as TJSONArray;

                for vCount3 := 0 to vGamemodesArray.Count - 1 do
                begin
                  SessionData.AvaliableSpells[vCount2].GameModes[vCount3] := Copy(vGamemodesArray.Items[vCount3].ToString, 2, Length(vGamemodesArray.Items[vCount3].ToString) - 2);
                end;

                  //Check for unavaliable spells, for the first release, only classic gamemode spells will be suported;
                if not (StringExistsInArrayOfStrings('CLASSIC', SessionData.AvaliableSpells[vCount2].GamemodesList)) then
                  SessionData.AvaliableSpells.Delete(vCount2);

              end;
            end;
          end;
        end;
      end;
    end;
  finally
    vResponseJSON.Free;
  end;
end;

end.


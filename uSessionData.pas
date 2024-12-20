unit uSessionData;

interface

uses
  SysUtils, System.Generics.Collections, System.Classes, System.JSON;

type
  TChampionInfo = class
  private
    fID: Integer;
    fName: string;
  public
    constructor Create(const pNome: string; pID: Integer);

    property ID: Integer read fID write fID;
    property Name: string read fName write fName;
  end;

  TSummonerSpellsInfo = class
  private
    fID: Integer;
    fName: string;
    fGamemodes: array of string;

    function GetGamemode(pIndex: Integer): string;
    procedure SetGamemode(pIndex: Integer; const pValue: string);
    function GetAllGamemodes: TArray<string>;
  public
    constructor Create(pID: Integer; const pName: string);

    property ID: Integer read fID write fID;
    property Name: string read fName write fName;
    property Gamemodes[Index: Integer]: string read GetGamemode write SetGamemode;
    property GamemodesList: TArray<string> read GetAllGamemodes;
  end;

  //Next Release;
//  TCurrentLobby = class
//  private
//    //Under development
//    fGamemode: string;
//    fMaxLobbySize: integer;
//  end;

  TLobbyParticipant = record
    fName: string;
    fDefaultParticipant: Boolean;

  public
    property Name: string read fName write fName;
    property DefaultParticipant: Boolean read fDefaultParticipant write fDefaultParticipant;
  end;

  TActionsLogger = class
    fMessages: TStringList;

  public
    procedure AddLog(const pMessage: string);

    property Messages: TStringList read fMessages write fMessages;
  end;

  TSessionData = class
  private
    fShouldInstantHoverChampion: Boolean;
    fShouldPickChampion: Boolean;
    fChampionPick: string;
    fShouldBanChampion: Boolean;
    fChampionBan: string;
    fShouldSelectSpell1: Boolean;
    fSpell1: string;
    fShouldSelectSpell2: Boolean;
    fSpell2: string;
    fShouldSendChatMessage: Boolean;
    fCurrentChatId: string;
    fChatMessage: string;
    fInstaShowPick: Boolean;
    fAutoAcceptQueue: Boolean;
    fAutoTradePick: Boolean;
    fPickBanLockDelay: Integer;
    fInstalockpick: Integer;
    fAllChampions: TObjectList<TChampionInfo>;
    fAvaliableChampions: TObjectList<TChampionInfo>;
    fAvaliableSpells: TObjectList<TSummonerSpellsInfo>;
    fLobbyParticipants: array of TLobbyParticipant;
    fSummonerName: string;
    fSummonerID: string;
    fActionsLogger: TActionsLogger;

    function GetLobbyParticipants(pIndex: Integer): string;
    procedure SetLobbyParticipants(pIndex: Integer; const pValue: string);
    function GetAllLobbyParticipants: TArray<TLobbyParticipant>;

    procedure LoadSettings;
    procedure SaveSettings;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ResetSettings;
    procedure ResetLobbyParticipants; //Need a special procedure, as it resets every champ select;

    property ShouldInstantHoverChampion: Boolean read fShouldInstantHoverChampion write fShouldInstantHoverChampion;
    property ShouldPickChampion: Boolean read fShouldPickChampion write fShouldPickChampion;
    property ChampionPick: string read fChampionPick write fChampionPick;
    property ShouldBanChampion: Boolean read fShouldBanChampion write fShouldBanChampion;
    property ChampionBan: string read fChampionBan write fChampionBan;
    property ShouldSelectSpell1: Boolean read fShouldSelectSpell1 write fShouldSelectSpell1;
    property Spell1: string read fSpell1 write fSpell1;
    property ShouldSelectSpell2: Boolean read fShouldSelectSpell2 write fShouldSelectSpell2;
    property Spell2: string read fSpell2 write fSpell2;
    property ShouldSendChatMessage: Boolean read fShouldSendChatMessage write fShouldSendChatMessage;
    property CurrentChatId: string read fCurrentChatId write fCurrentChatId;
    property ChatMessage: string read fChatMessage write fChatMessage;
    property InstaShowPick: Boolean read fInstaShowPick write fInstaShowPick;
    property AutoAcceptQueue: Boolean read fAutoAcceptQueue write fAutoAcceptQueue;
    property AutoTradePick: Boolean read fAutoTradePick write fAutoTradePick;
    property PickBanLockDelay: Integer read fPickBanLockDelay write fPickBanLockDelay;
    property Instalockpick: Integer read fInstalockpick write fInstalockpick;
    property AllChampions: TObjectList<TChampionInfo> read fAllChampions write fAllChampions;
    property AvaliableChampions: TObjectList<TChampionInfo> read fAvaliableChampions write fAvaliableChampions;
    property AvaliableSpells: TObjectList<TSummonerSpellsInfo> read fAvaliableSpells write fAvaliableSpells;
    property LobbyParticipants[Index: Integer]: string read GetLobbyParticipants write SetLobbyParticipants;
    property LobbyParticipantsList: TArray<TLobbyParticipant> read GetAllLobbyParticipants;
    property SummonerName: string read fSummonerName write fSummonerName;
    property SummonerID: string read fSummonerID write fSummonerID;
    property ActionsLogger: TActionsLogger read fActionsLogger write fActionsLogger;
  end;

var
  SessionData: TSessionData;

implementation

{ TSessionData }

constructor TSessionData.Create;
begin
  fShouldInstantHoverChampion := False;
  fShouldPickChampion := False;
  fChampionPick := '';
  fShouldBanChampion := False;
  fChampionBan := '';
  fShouldSelectSpell1 := False;
  fSpell1 := '';
  fShouldSelectSpell2 := False;
  fSpell2 := '';
  fChatMessage := '';
  fCurrentChatId := '';
  fShouldSendChatMessage := True;
  fInstaShowPick := False;
  fAutoAcceptQueue := False;
  fAutoTradePick := False;
  fPickBanLockDelay := 0;
  fInstalockpick := 0;
  fAllChampions := TObjectList<TChampionInfo>.Create(True);
  fAvaliableChampions := TObjectList<TChampionInfo>.Create(True);
  fAvaliableSpells := TObjectList<TSummonerSpellsInfo>.Create(True);
  fSummonerName := '';
  fSummonerID := '';

  fActionsLogger := TActionsLogger.Create;
  fActionsLogger.Messages := TStringList.Create;

  LoadSettings;
end;

destructor TSessionData.Destroy;
var
  vCount: Integer;
begin
  SaveSettings;

  for vCount := 0 to fAllChampions.Count - 1 do
    FreeAndNil(fAllChampions[vCount]);

  fAllChampions.Clear;

  FreeAndNil(fAllChampions);

  for vCount := 0 to fAvaliableChampions.Count - 1 do
    FreeAndNil(fAvaliableChampions[vCount]);

  fAvaliableChampions.Clear;

  FreeAndNil(fAvaliableChampions);

  for vCount := 0 to fAvaliableSpells.Count - 1 do
    FreeAndNil(fAvaliableSpells[vCount]);

  fAvaliableSpells.Clear;

  FreeAndNil(fAvaliableSpells);

  FreeAndNil(fActionsLogger.Messages);
  FreeAndNil(fActionsLogger);
  inherited Destroy;
end;

procedure TSessionData.ResetLobbyParticipants;
begin
  SetLength(fLobbyParticipants, 0);
end;

procedure TSessionData.ResetSettings;
begin
  fAllChampions.Clear;
  fAvaliableChampions.Clear;
  fAvaliableSpells.Clear;
end;

function TSessionData.GetAllLobbyParticipants: TArray<TLobbyParticipant>;
var
  vCount: Integer;
begin
  SetLength(Result, Length(fLobbyParticipants));

  for vCount := Low(fLobbyParticipants) to High(fLobbyParticipants) do
    Result[vCount] := fLobbyParticipants[vCount];
end;

function TSessionData.GetLobbyParticipants(pIndex: Integer): string;
begin
  if (pIndex >= 0) and (pIndex < Length(fLobbyParticipants)) then
    Result := fLobbyParticipants[pIndex].Name
  else
    Result := '';
end;

procedure TSessionData.LoadSettings;
var
  SettingsObject: TJSONObject;
  SettingsFile: TStringList;
  SettingsFilePath: string;
begin
  SettingsFilePath := GetCurrentDir + '\settings.json';

  if FileExists(SettingsFilePath) then
  begin
    SettingsFile := TStringList.Create;
    try
      SettingsFile.LoadFromFile(SettingsFilePath);
      SettingsObject := TJSONObject.ParseJSONValue(SettingsFile.Text) as TJSONObject;
      try
        if Assigned(SettingsObject) then
        begin
          if Assigned(SettingsObject.Values['autoAcceptQueue']) then
            fAutoAcceptQueue := SettingsObject.GetValue('autoAcceptQueue').AsType<Boolean>;

          if Assigned(SettingsObject.Values['autoTradePick']) then
            fAutoTradePick := SettingsObject.GetValue('autoTradePick').AsType<Boolean>;

          if Assigned(SettingsObject.Values['shouldInstantHoverChampion']) then
            fShouldInstantHoverChampion := SettingsObject.GetValue('shouldInstantHoverChampion').AsType<Boolean>;

          if Assigned(SettingsObject.Values['shouldPickChampion']) then
            fShouldPickChampion := SettingsObject.GetValue('shouldPickChampion').AsType<Boolean>;

          if Assigned(SettingsObject.Values['championId']) then
            fChampionPick := SettingsObject.GetValue('championId').AsType<string>;

          if Assigned(SettingsObject.Values['shouldBanChampion']) then
            fShouldBanChampion := SettingsObject.GetValue('shouldBanChampion').AsType<Boolean>;

          if Assigned(SettingsObject.Values['championBanId']) then
            fChampionBan := SettingsObject.GetValue('championBanId').AsType<string>;

          if Assigned(SettingsObject.Values['shouldSelectSpell1']) then
            fShouldSelectSpell1 := SettingsObject.GetValue('shouldSelectSpell1').AsType<Boolean>;

          if Assigned(SettingsObject.Values['spell1Id']) then
            fSpell1 := SettingsObject.GetValue('spell1Id').AsType<string>;

          if Assigned(SettingsObject.Values['shouldSelectSpell2']) then
            fShouldSelectSpell2 := SettingsObject.GetValue('shouldSelectSpell2').AsType<Boolean>;

          if Assigned(SettingsObject.Values['spell2Id']) then
            fSpell2 := SettingsObject.GetValue('spell2Id').AsType<string>;

          if Assigned(SettingsObject.Values['shouldSendChatMessage']) then
            fShouldSendChatMessage := SettingsObject.GetValue('shouldSendChatMessage').AsType<Boolean>;

          if Assigned(SettingsObject.Values['chatMessage']) then
            fChatMessage := SettingsObject.GetValue('chatMessage').AsType<string>;
        end;
      finally
        SettingsObject.Free;
      end;
    finally
      SettingsFile.Free;
    end;
  end;
end;

procedure TSessionData.SaveSettings;
var
  SettingsObject: TJSONObject;
  SettingsFile: TStringList;
begin
  SettingsObject := TJSONObject.Create;
  try
    SettingsObject.AddPair('autoAcceptQueue', TJSONBool.Create(fAutoAcceptQueue));
    SettingsObject.AddPair('autoTradePick', TJSONBool.Create(fAutoTradePick));
    SettingsObject.AddPair('shouldInstantHoverChampion', TJSONBool.Create(fShouldInstantHoverChampion));
    SettingsObject.AddPair('shouldPickChampion', TJSONBool.Create(fShouldPickChampion));
    SettingsObject.AddPair('championId', TJSONString.Create(fChampionPick));
    SettingsObject.AddPair('shouldBanChampion', TJSONBool.Create(fShouldBanChampion));
    SettingsObject.AddPair('championBanId', TJSONString.Create(fChampionBan));
    SettingsObject.AddPair('shouldSelectSpell1', TJSONBool.Create(fShouldSelectSpell1));
    SettingsObject.AddPair('spell1Id', TJSONString.Create(fSpell1));
    SettingsObject.AddPair('shouldSelectSpell2', TJSONBool.Create(fShouldSelectSpell2));
    SettingsObject.AddPair('spell2Id', TJSONString.Create(fSpell2));
    SettingsObject.AddPair('shouldSendChatMessage', TJSONBool.Create(fShouldSendChatMessage));
    SettingsObject.AddPair('chatMessage', TJSONString.Create(fChatMessage));

    SettingsFile := TStringList.Create;
    try
      SettingsFile.Text := SettingsObject.ToJSON;
      SettingsFile.SaveToFile(GetCurrentDir + '\settings.json');
    finally
      SettingsFile.Free;
    end;
  finally
    SettingsObject.Free;
  end;
end;

procedure TSessionData.SetLobbyParticipants(pIndex: Integer; const pValue: string);
begin
  if pIndex < 0 then
    Exit;

  if pIndex >= Length(fLobbyParticipants) then
    SetLength(fLobbyParticipants, pIndex + 1);

  fLobbyParticipants[pIndex].Name := pValue;
  fLobbyParticipants[pIndex].DefaultParticipant := False;
end;

{ TChampionInfo }

constructor TChampionInfo.Create(const pNome: string; pID: Integer);
begin
  fName := pNome;
  fID := pID;
end;

{ TSummonerSpellsInfo }

constructor TSummonerSpellsInfo.Create(pID: Integer; const pName: string);
begin
  fID := pID;
  fName := pName;
end;

function TSummonerSpellsInfo.GetAllGamemodes: TArray<string>;
var
  vCount: Integer;
begin
  SetLength(Result, Length(fGamemodes));

  for vCount := Low(fGamemodes) to High(fGamemodes) do
    Result[vCount] := fGamemodes[vCount];
end;

function TSummonerSpellsInfo.GetGamemode(pIndex: Integer): string;
begin
  if (pIndex >= 0) and (pIndex < Length(fGamemodes)) then
    Result := fGamemodes[pIndex]
  else
    Result := '';
end;

procedure TSummonerSpellsInfo.SetGamemode(pIndex: Integer; const pValue: string);
begin
  if pIndex < 0 then
    Exit;

  if pIndex >= Length(fGamemodes) then
    SetLength(fGamemodes, pIndex + 1);

  fGamemodes[pIndex] := pValue;
end;

{ TActionsLogger }

procedure TActionsLogger.AddLog(const pMessage: string);
begin
  fMessages.Add(FormatDateTime('[dd/mm/yyyy - hh:nn:ss.zzz] ', Now) + pMessage);
end;

end.


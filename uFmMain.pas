unit uFmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  uAuthManager, Vcl.StdCtrls, uSessionData, System.Threading, Vcl.ColorGrd, Vcl.WinXCtrls, Vcl.ExtCtrls, ShellAPI, Vcl.Imaging.jpeg, Vcl.Tabs,
  Vcl.ComCtrls, uUtils;

type
  TMainForm = class(TForm)
    cbChampionPick: TComboBox;
    cbSpellPick1: TComboBox;
    cbSpellPick2: TComboBox;
    chbAutoChampion: TCheckBox;
    chbAutoSpell1: TCheckBox;
    chbAutoSpell2: TCheckBox;
    chbAutoChampionBan: TCheckBox;
    cbChampionBan: TComboBox;
    lbChampionPick: TLabel;
    lbChampionBan: TLabel;
    lbSummonerSpell1: TLabel;
    lbSummonerSpell2: TLabel;
    lbChatMessage: TLabel;
    chbAutoChatMessage: TCheckBox;
    edtSummoner1: TEdit;
    edtSummoner2: TEdit;
    edtSummoner3: TEdit;
    edtSummoner4: TEdit;
    edtSummoner5: TEdit;
    lbLobbyParticipants: TLabel;
    btnSearchOPGG: TButton;
    chbAutoQueue: TCheckBox;
    chbAutoTradePick: TCheckBox;
    chbInstaHoverChampion: TCheckBox;
    mmChatMessage: TMemo;
    pcPageControl: TPageControl;
    tsChampSelect: TTabSheet;
    tsOptions: TTabSheet;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    dvDiviver2: TPanel;
    dvDivider1: TPanel;
    mmLogger: TMemo;
    btnKillClient: TButton;
    btnDodgeQueue: TButton;
    pnLoadingPanel: TPanel;
    pnLoadingCircle: TActivityIndicator;
    tsLogger: TTabSheet;
    //TODO: Add secondary options if the selected champion is not available;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ComboBox4: TComboBox;
    ComboBox5: TComboBox;
    ComboBox6: TComboBox;
    ComboBox7: TComboBox;
    ComboBox8: TComboBox;
    CheckBox1: TCheckBox;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cbSpellPick1Change(Sender: TObject);
    procedure cbSpellPick2Change(Sender: TObject);
    procedure chbAutoChampionClick(Sender: TObject);
    procedure chbAutoSpell1Click(Sender: TObject);
    procedure chbAutoSpell2Click(Sender: TObject);
    procedure chbAutoChampionBanClick(Sender: TObject);
    procedure cbChampionPickChange(Sender: TObject);
    procedure cbChampionBanChange(Sender: TObject);
    procedure mmChatMessageChange(Sender: TObject);
    procedure chbAutoChatMessageClick(Sender: TObject);
    procedure btnSearchOPGGClick(Sender: TObject);
    procedure chbAutoQueueClick(Sender: TObject);
    procedure chbAutoTradePickClick(Sender: TObject);
    procedure chbInstaHoverChampionClick(Sender: TObject);
    procedure btnKillClientClick(Sender: TObject);
    procedure btnDodgeQueueClick(Sender: TObject);
  private
    fAuthManager: TAuthManager;
    fSelectedSpell1: Integer;
    fSelectedSpell2: Integer;
    fSelectedChampionPick: string;
    fSelectedChampionBan: string;
    fMessageLoaded: Boolean;

    procedure ResetUI;
    procedure OnDataUpdate(Sender: TObject);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.cbChampionPickChange(Sender: TObject);
begin
  if cbChampionPick.Text = fSelectedChampionBan then
    cbChampionBan.ItemIndex := cbChampionBan.Items.IndexOf(fSelectedChampionPick);

  fSelectedChampionPick := cbChampionPick.Text;
  fSelectedChampionBan := cbChampionBan.Text;

  SessionData.ChampionPick := IntToStr(TChampionInfo(cbChampionPick.Items.Objects[cbChampionPick.ItemIndex]).ID);
end;

procedure TMainForm.btnSearchOPGGClick(Sender: TObject);
var
  vCount: Integer;
  vLobbyParticipantsEdit: TEdit;
  vLobbyParticipantsList: string;
begin
  vLobbyParticipantsList := '';

  for vCount := 0 to Length(SessionData.LobbyParticipantsList) - 1 do
  begin
    vLobbyParticipantsEdit := FindComponent('edtSummoner' + IntToStr(vCount + 1)) as TEdit;

    if (Assigned(vLobbyParticipantsEdit)) and (not SessionData.LobbyParticipantsList[vCount].DefaultParticipant) then
    begin
      if vCount = 4 then
        vLobbyParticipantsList := vLobbyParticipantsList + vLobbyParticipantsEdit.Text
      else
        vLobbyParticipantsList := vLobbyParticipantsList + vLobbyParticipantsEdit.Text + ',';
    end;
  end;

  if vLobbyParticipantsList <> '' then
    ShellExecute(0, 'open', PChar('https://www.op.gg/multisearch/br?summoners=' + vLobbyParticipantsList), nil, nil, SW_HIDE);

  //Not working after nickname changes from Riot;
end;

procedure TMainForm.btnDodgeQueueClick(Sender: TObject);
begin
  if Assigned(fAuthManager) and Assigned(fAuthManager.LeagueHandler) then
    fAuthManager.LeagueHandler.DodgeQueue;
end;

procedure TMainForm.btnKillClientClick(Sender: TObject);
begin
  KillProcessByName('RiotClientServices.exe');
  KillProcessByName('LeagueClient.exe');
end;

procedure TMainForm.cbChampionBanChange(Sender: TObject);
begin
  if cbChampionBan.Text = fSelectedChampionPick then
    cbChampionPick.ItemIndex := cbChampionPick.Items.IndexOf(fSelectedChampionBan);

  fSelectedChampionPick := cbChampionPick.Text;
  fSelectedChampionBan := cbChampionBan.Text;

  SessionData.ChampionBan := IntToStr(TChampionInfo(cbChampionBan.Items.Objects[cbChampionBan.ItemIndex]).ID);
end;

procedure TMainForm.cbSpellPick1Change(Sender: TObject);
begin
  if cbSpellPick1.ItemIndex = fSelectedSpell2 then
    cbSpellPick2.ItemIndex := fSelectedSpell1;

  fSelectedSpell1 := cbSpellPick1.ItemIndex;
  fSelectedSpell2 := cbSpellPick2.ItemIndex;

  SessionData.Spell1 := IntToStr(TSummonerSpellsInfo(cbSpellPick1.Items.Objects[cbSpellPick1.ItemIndex]).ID);
end;

procedure TMainForm.cbSpellPick2Change(Sender: TObject);
begin
  if cbSpellPick2.ItemIndex = fSelectedSpell1 then
    cbSpellPick1.ItemIndex := fSelectedSpell2;

  fSelectedSpell1 := cbSpellPick1.ItemIndex;
  fSelectedSpell2 := cbSpellPick2.ItemIndex;

  SessionData.Spell2 := IntToStr(TSummonerSpellsInfo(cbSpellPick2.Items.Objects[cbSpellPick2.ItemIndex]).ID);
end;

procedure TMainForm.chbAutoChampionClick(Sender: TObject);
begin
  cbChampionPick.Enabled := not chbAutoChampion.Checked;

  SessionData.ShouldPickChampion := chbAutoChampion.Checked;
end;

procedure TMainForm.chbAutoChampionBanClick(Sender: TObject);
begin
  cbChampionBan.Enabled := not chbAutoChampionBan.Checked;

  SessionData.ShouldBanChampion := chbAutoChampionBan.Checked;
end;

procedure TMainForm.chbAutoSpell1Click(Sender: TObject);
begin
  cbSpellPick1.Enabled := not chbAutoSpell1.Checked;

  SessionData.ShouldSelectSpell1 := chbAutoSpell1.Checked;
end;

procedure TMainForm.chbAutoSpell2Click(Sender: TObject);
begin
  cbSpellPick2.Enabled := not chbAutoSpell2.Checked;

  SessionData.ShouldSelectSpell2 := chbAutoSpell2.Checked;
end;

procedure TMainForm.chbAutoTradePickClick(Sender: TObject);
begin
  SessionData.AutoTradePick := chbAutoTradePick.Checked;
end;

procedure TMainForm.chbInstaHoverChampionClick(Sender: TObject);
begin
  SessionData.ShouldInstantHoverChampion := chbInstaHoverChampion.Checked;
end;

procedure TMainForm.chbAutoChatMessageClick(Sender: TObject);
begin
  if mmChatMessage.Text = '' then
    chbAutoChatMessage.Checked := False;

  mmChatMessage.Enabled := not chbAutoChatMessage.Checked;

  SessionData.ShouldSendChatMessage := chbAutoChatMessage.Checked;
end;

procedure TMainForm.chbAutoQueueClick(Sender: TObject);
begin
  SessionData.AutoAcceptQueue := chbAutoQueue.Checked;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(fAuthManager) then
  begin
    fAuthManager.Terminate;
    fAuthManager.WaitFor;
    FreeAndNil(fAuthManager);
  end;

  FreeAndNil(SessionData);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fAuthManager := TAuthManager.Create;
  fAuthManager.LeagueHandler.OnDataUpdate := OnDataUpdate;

  cbChampionPick.Sorted := True;
  cbChampionBan.Sorted := True;
  cbSpellPick1.Sorted := True;
  cbSpellPick2.Sorted := True;

  ResetUI;
end;

procedure TMainForm.mmChatMessageChange(Sender: TObject);
begin
  if fMessageLoaded then
    SessionData.ChatMessage := mmChatMessage.Text;
end;

procedure TMainForm.OnDataUpdate(Sender: TObject);
var
  vCount: Integer;
  vLobbyParticipantsEdit: TEdit;
begin
  try
    if Assigned(SessionData) and Assigned(fAuthManager) and Assigned(fAuthManager.LeagueHandler) and (not fAuthManager.LeagueHandler.ClientClosed) then
    begin
      pnLoadingPanel.Visible := False;
      pnLoadingCircle.StopAnimation;

      Label1.Caption := fAuthManager.LeagueHandler.Status;
      mmLogger.Lines := SessionData.ActionsLogger.Messages;

      if SessionData.ActionsLogger.Messages.Count > 0 then
      begin
        mmLogger.SelStart := Pos(SessionData.ActionsLogger.Messages[SessionData.ActionsLogger.Messages.Count - 1], mmLogger.Text) + Length(SessionData.ActionsLogger.Messages[SessionData.ActionsLogger.Messages.Count - 1]);
        mmLogger.SelLength := 0;
        SendMessage(mmLogger.Handle, EM_SCROLLCARET, 0, 0);
      end;

      //Auto queue accept
      chbAutoQueue.Checked := SessionData.AutoAcceptQueue;

      //Auto trade accept
      chbAutoTradePick.Checked := SessionData.AutoTradePick;

      //Instant hover champion
      chbInstaHoverChampion.Checked := SessionData.ShouldInstantHoverChampion;

      //Champion Pick
      if (SessionData.AvaliableChampions.Count > 0) and (cbChampionPick.Items.Count <> SessionData.AvaliableChampions.Count) then
      begin
        cbChampionPick.Items.BeginUpdate;
        cbChampionPick.Clear;

        for vCount := 0 to SessionData.AvaliableChampions.Count - 1 do
        begin
          cbChampionPick.Items.AddObject(SessionData.AvaliableChampions[vCount].Name, SessionData.AvaliableChampions[vCount]);
        end;

        cbChampionPick.ItemIndex := 0;
        fSelectedChampionPick := cbChampionPick.Text;

        if SessionData.ChampionPick <> '' then
        begin
          for vCount := 0 to cbChampionPick.Items.Count - 1 do
          begin
            if IntToStr(TChampionInfo(cbChampionPick.Items.Objects[vCount]).ID) = SessionData.ChampionPick then
              cbChampionPick.ItemIndex := vCount;
          end;
        end
        else
          SessionData.ChampionPick := IntToStr(TChampionInfo(cbChampionPick.Items.Objects[cbChampionPick.ItemIndex]).ID);

        cbChampionPick.Items.EndUpdate;
        chbAutoChampion.Checked := SessionData.ShouldPickChampion;
      end;

      //Champion Ban
      if (SessionData.AllChampions.Count > 0) and (cbChampionBan.Items.Count <> SessionData.AllChampions.Count) then
      begin
        cbChampionBan.Items.BeginUpdate;
        cbChampionBan.Clear;

        for vCount := 0 to SessionData.AllChampions.Count - 1 do
        begin
          cbChampionBan.Items.AddObject(SessionData.AllChampions[vCount].Name, SessionData.AllChampions[vCount]);
        end;

        if TChampionInfo(cbChampionPick.Items.Objects[0]).Name = TChampionInfo(cbChampionBan.Items.Objects[0]).Name then
          cbChampionBan.ItemIndex := 1
        else
          cbChampionBan.ItemIndex := 0;

        fSelectedChampionBan := cbChampionBan.Text;

        if SessionData.ChampionBan <> '' then
        begin
          for vCount := 0 to cbChampionBan.Items.Count - 1 do
          begin
            if IntToStr(TChampionInfo(cbChampionBan.Items.Objects[vCount]).ID) = SessionData.ChampionBan then
              cbChampionBan.ItemIndex := vCount;
          end;
        end
        else
          SessionData.ChampionBan := IntToStr(TChampionInfo(cbChampionBan.Items.Objects[cbChampionBan.ItemIndex]).ID);

        cbChampionBan.Items.EndUpdate;

        chbAutoChampionBan.Checked := SessionData.ShouldBanChampion;
      end;

      //Spells (D)
      if (SessionData.AvaliableSpells.Count > 0) and (cbSpellPick1.Items.Count <> (SessionData.AvaliableSpells.Count)) then
      begin
        cbSpellPick1.Items.BeginUpdate;
        cbSpellPick1.Clear;

        for vCount := 0 to SessionData.AvaliableSpells.Count - 1 do
        begin
          cbSpellPick1.Items.AddObject(SessionData.AvaliableSpells[vCount].Name, SessionData.AvaliableSpells[vCount]);
        end;

        cbSpellPick1.ItemIndex := 0;

        if SessionData.Spell1 <> '' then
        begin
          for vCount := 0 to cbSpellPick1.Items.Count - 1 do
          begin
            if IntToStr(TChampionInfo(cbSpellPick1.Items.Objects[vCount]).ID) = SessionData.Spell1 then
              cbSpellPick1.ItemIndex := vCount;
          end;
        end
        else
          SessionData.Spell1 := IntToStr(TChampionInfo(cbSpellPick1.Items.Objects[cbSpellPick1.ItemIndex]).ID);

        cbSpellPick1.Items.EndUpdate;

        fSelectedSpell1 := cbSpellPick1.ItemIndex;

        chbAutoSpell1.Checked := SessionData.ShouldSelectSpell1;
      end;

      //Spells (F)
      if (SessionData.AvaliableSpells.Count > 0) and (cbSpellPick2.Items.Count <> (SessionData.AvaliableSpells.Count)) then
      begin
        cbSpellPick2.Items.BeginUpdate;
        cbSpellPick2.Clear;

        for vCount := 0 to SessionData.AvaliableSpells.Count - 1 do
        begin
          cbSpellPick2.Items.AddObject(SessionData.AvaliableSpells[vCount].Name, SessionData.AvaliableSpells[vCount]);
        end;

        cbSpellPick2.ItemIndex := 1;

        if SessionData.Spell2 <> '' then
        begin
          for vCount := 0 to cbSpellPick2.Items.Count - 1 do
          begin
            if IntToStr(TChampionInfo(cbSpellPick2.Items.Objects[vCount]).ID) = SessionData.Spell2 then
              cbSpellPick2.ItemIndex := vCount;
          end;
        end
        else
          SessionData.Spell2 := IntToStr(TChampionInfo(cbSpellPick2.Items.Objects[cbSpellPick2.ItemIndex]).ID);

        cbSpellPick2.Items.EndUpdate;

        fSelectedSpell2 := cbSpellPick2.ItemIndex;

        chbAutoSpell2.Checked := SessionData.ShouldSelectSpell2;
      end;

      //Chat Message
      if SessionData.ChatMessage <> '' then
      begin
        mmChatMessage.Text := SessionData.ChatMessage;
      end;

      chbAutoChatMessage.Checked := SessionData.ShouldSendChatMessage;

      fMessageLoaded := True;

      //Lobby Participants
      for vCount := 0 to 4 do
      begin
        vLobbyParticipantsEdit := FindComponent('edtSummoner' + IntToStr(vCount + 1)) as TEdit;

        if Assigned(vLobbyParticipantsEdit) then
        begin
          if SessionData.LobbyParticipants[vCount] <> '' then
          begin
            vLobbyParticipantsEdit.Enabled := True;
            vLobbyParticipantsEdit.Text := SessionData.LobbyParticipants[vCount]
          end
          else
          begin
            vLobbyParticipantsEdit.Enabled := False;
            vLobbyParticipantsEdit.Text := 'Summoner ' + IntToStr(vCount + 1);
          end;
        end;
      end;

      MainForm.Caption := 'LOL Auto | Summoner: ' + SessionData.SummonerName;
    end
    else
      ResetUI;

    //debugging
    Edit1.Text := 'https://127.0.0.1:' + IntToStr(fAuthManager.Port) + ' | ' + fAuthManager.AuthToken;
    Edit2.Text := 'https://127.0.0.1:' + IntToStr(fAuthManager.RiotPort) + ' | ' + fAuthManager.RiotAuthToken;
  finally
    chbAutoQueue.Enabled := (SessionData.AvaliableChampions.Count > 0);
    chbAutoTradePick.Enabled := (SessionData.AvaliableChampions.Count > 0);
    chbInstaHoverChampion.Enabled := (SessionData.AvaliableChampions.Count > 0);

    chbAutoChampion.Enabled := (SessionData.AvaliableChampions.Count > 0);
    cbChampionPick.Enabled := (SessionData.AvaliableChampions.Count > 0) and (not chbAutoChampion.Checked);

    chbAutoChampionBan.Enabled := (SessionData.AllChampions.Count > 0);
    cbChampionBan.Enabled := (SessionData.AllChampions.Count > 0) and (not chbAutoChampionBan.Checked);

    chbAutoSpell1.Enabled := (SessionData.AvaliableSpells.Count > 0);
    cbSpellPick1.Enabled := (SessionData.AvaliableSpells.Count > 0) and (not chbAutoSpell1.Checked);

    chbAutoSpell2.Enabled := (SessionData.AvaliableSpells.Count > 0);
    cbSpellPick2.Enabled := (SessionData.AvaliableSpells.Count > 0) and (not chbAutoSpell2.Checked);

    chbAutoChatMessage.Enabled := (SessionData.AvaliableChampions.Count > 0);
    mmChatMessage.Enabled := (SessionData.AvaliableChampions.Count > 0) and (not chbAutoChatMessage.Checked);

    btnSearchOPGG.Enabled := Length(SessionData.LobbyParticipantsList) >= 1;
  end;
end;

procedure TMainForm.ResetUI;
begin
  MainForm.Caption := 'LOL Auto';

  mmLogger.Text := '';
  mmLogger.Lines.Clear;

  pnLoadingPanel.Height := MainForm.Height;
  pnLoadingPanel.Width := MainForm.Width;
  pnLoadingPanel.Top := 0;
  pnLoadingPanel.Left := 0;
  pnLoadingPanel.Visible := True;

  pnLoadingCircle.Top := Round(MainForm.Height / 2) - 90;
  pnLoadingCircle.Left := Round(MainForm.Width / 2) - 32;

  if not pnLoadingCircle.Animate then
    pnLoadingCircle.StartAnimation;

  chbAutoQueue.Enabled := False;
  chbAutoTradePick.Enabled := False;
  chbInstaHoverChampion.Enabled := False;

  cbChampionPick.Items.Clear;
  cbChampionPick.Items.Add('Loading champions...');
  cbChampionPick.ItemIndex := 0;
  cbChampionPick.Enabled := False;
  chbAutoChampion.Enabled := False;

  cbChampionBan.Items.Clear;
  cbChampionBan.Items.Add('Loading champions...');
  cbChampionBan.ItemIndex := 0;
  cbChampionBan.Enabled := False;
  chbAutoChampionBan.Enabled := False;

  cbSpellPick1.Items.Clear;
  cbSpellPick1.Items.Add('Loading spells...');
  cbSpellPick1.ItemIndex := 0;
  cbSpellPick1.Enabled := False;
  chbAutoSpell1.Enabled := False;

  cbSpellPick2.Items.Clear;
  cbSpellPick2.Items.Add('Loading spells...');
  cbSpellPick2.ItemIndex := 0;
  cbSpellPick2.Enabled := False;
  chbAutoSpell2.Enabled := False;

  mmChatMessage.Text := '';
  mmChatMessage.Enabled := False;
  chbAutoChatMessage.Enabled := False;
  fMessageLoaded := False;

  edtSummoner1.Enabled := False;
  edtSummoner2.Enabled := False;
  edtSummoner3.Enabled := False;
  edtSummoner4.Enabled := False;
  edtSummoner5.Enabled := False;

  btnSearchOPGG.Enabled := False;
end;

end.


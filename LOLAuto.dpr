program LOLAuto;

uses
  Vcl.Forms,
  uFmMain in 'uFmMain.pas' {MainForm},
  uAuthManager in 'uAuthManager.pas',
  uUtils in 'uUtils.pas',
  uLeagueHandler in 'uLeagueHandler.pas',
  uSessionData in 'uSessionData.pas';

{$R *.res}

begin
  Application.Initialize;
  SessionData := TSessionData.Create;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.

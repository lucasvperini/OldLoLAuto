unit uUtils;

interface

uses
  RegularExpressions, SysUtils, Windows, TlHelp32, uSessionData;

function ExtractRegexText(const pText, pParameter: string): string;
function StringExistsInArrayOfStrings(const pString: string; pStringArray: array of string): Boolean;
function ExtractAtSignPrefix(const pString: string): string;
function GetProcessIDByName(const pProcessName: string): Integer;
procedure StartProcess(const pExecutablePath, pArguments: string);
procedure KillProcessByName(const pProcessName: string);
function GetChampionNameByID(pChampionID: integer): string;

implementation

function ExtractRegexText(const pText, pParameter: string): string;
var
  vRegularExpression: TRegEx;
  vMatches: TMatchCollection;
  vMatch: TMatch;
begin
  vRegularExpression := TRegEx.Create(Format('%s=([^\s"]+)', [pParameter]));
  vMatches := vRegularExpression.Matches(pText);

  for vMatch in vMatches do
  begin
    Result := vMatch.Groups[1].Value;
    Exit;
  end;

  Result := '';
end;

function StringExistsInArrayOfStrings(const pString: string; pStringArray: array of string): Boolean;
var
  vCount: Integer;
begin
  Result := False;

  for vCount := 0 to Length(pStringArray) - 1 do
  begin
    if SameText(pString, pStringArray[vCount]) then
    begin
      Result := True;
      Exit;
    end;
  end;

end;

function ExtractAtSignPrefix(const pString: string): string;
var
  vAtSignIndex: Integer;
begin
  vAtSignIndex := Pos('@', pString);

  if vAtSignIndex > 0 then
  begin
    Result := Copy(pString, 1, vAtSignIndex - 1);
  end
  else
  begin
    Result := pString;
  end;
end;

function GetProcessIDByName(const pProcessName: string): Integer;
var
  vContinueLoop: BOOL;
  vSnapshotHandle: THandle;
  vEntry: TProcessEntry32;
begin
  Result := 0;
  vSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if vSnapshotHandle = INVALID_HANDLE_VALUE then
    Exit;

  try
    vEntry.dwSize := SizeOf(vEntry);
    vContinueLoop := Process32First(vSnapshotHandle, vEntry);

    while vContinueLoop do
    begin
      if SameText(ExtractFileName(vEntry.szExeFile), pProcessName) then
      begin
        Result := vEntry.th32ProcessID;
        Break;
      end;
      vContinueLoop := Process32Next(vSnapshotHandle, vEntry);
    end;

  finally
    CloseHandle(vSnapshotHandle);
  end;
end;

procedure StartProcess(const pExecutablePath, pArguments: string);
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);

  if CreateProcess(PChar(pExecutablePath), PChar(pArguments), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
  begin
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
end;

procedure KillProcessByName(const pProcessName: string);
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if (UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(pProcessName)) then
    begin
      try
        TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FProcessEntry32.th32ProcessID), 0);
      except
      end;
    end;

    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;

  CloseHandle(FSnapshotHandle);
end;

function GetChampionNameByID(pChampionID: integer): string;
var
  vCount: Integer;
begin
  Result := 'None';

  if Assigned(SessionData) then
  begin
    for vCount := 0 to SessionData.AllChampions.Count - 1 do
    begin
      if SessionData.AllChampions[vCount].ID = pChampionID then
      begin
        Result := SessionData.AllChampions[vCount].Name;
        Break;
      end;
    end;
  end;
end;

end.


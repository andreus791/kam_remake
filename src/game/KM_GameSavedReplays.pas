unit KM_GameSavedReplays;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, Generics.Collections;

type
  TKMSavedReplay = class
  private
    fStream: TKMemoryStream;
    fTick: Cardinal;
    // Opened spectator menu, viewports position etc...
  public
    constructor Create(aStream: TKMemoryStream; aTick: Cardinal);
    destructor Destroy(); override;

    property Stream: TKMemoryStream read fStream;
    property Tick: Cardinal read fTick;
  end;

  TKMSavedReplays = class
  private
    fReplaySaves: TDictionary<Cardinal, TKMSavedReplay>;

    function GetCount(): Integer;
    function GetSave(aTick: Cardinal): TKMSavedReplay;
    function GetStream(aTick: Cardinal): TKMemoryStream;
  public
    constructor Create();
    destructor Destroy; override;

    property Count: Integer read GetCount;
    property Replay[aTick: Cardinal]: TKMSavedReplay read GetSave;
    property Stream[aTick: Cardinal]: TKMemoryStream read GetStream; default;
    function Contains(aTick: Cardinal): Boolean;
    procedure FillTicks(aTicksList: TList<Cardinal>);

    procedure NewSave(aStream: TKMemoryStream; aTick: Cardinal);
  end;

implementation
uses
  SysUtils;


{ TKMSavedReplays }
constructor TKMSavedReplays.Create();
begin
  fReplaySaves := TDictionary<Cardinal, TKMSavedReplay>.Create();
end;


destructor TKMSavedReplays.Destroy();
begin
  fReplaySaves.Free; // TKMList will free all objects of the list
  inherited;
end;


function TKMSavedReplays.GetCount(): Integer;
begin
  Result := fReplaySaves.Count;
end;


function TKMSavedReplays.Contains(aTick: Cardinal): Boolean;
begin
  Result := fReplaySaves.ContainsKey(aTick);
end;


procedure TKMSavedReplays.FillTicks(aTicksList: TList<Cardinal>);
var
  Tick: Cardinal;
begin
  for Tick in fReplaySaves.Keys do
    aTicksList.Add(Tick);
end;


function TKMSavedReplays.GetSave(aTick: Cardinal): TKMSavedReplay;
begin
  Result := nil;
  if fReplaySaves.ContainsKey(aTick) then
    Result := fReplaySaves[aTick];
end;


function TKMSavedReplays.GetStream(aTick: Cardinal): TKMemoryStream;
var
  Rpl: TKMSavedReplay;
begin
  Result := nil;
  if fReplaySaves.TryGetValue(aTick, Rpl) then
    Result := Rpl.Stream;
end;


procedure TKMSavedReplays.NewSave(aStream: TKMemoryStream; aTick: Cardinal);
begin
  fReplaySaves.Add(aTick, TKMSavedReplay.Create(aStream, aTick) );
end;



{ TKMSavedReplay }
constructor TKMSavedReplay.Create(aStream: TKMemoryStream; aTick: Cardinal);
begin
  fStream := aStream;
  fTick := aTick;
end;


destructor TKMSavedReplay.Destroy();
begin
  fStream.Free;
  inherited;
end;


end.

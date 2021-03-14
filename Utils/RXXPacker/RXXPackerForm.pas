unit RXXPackerForm;
{$I ..\..\KaM_Remake.inc}
interface
uses
  Classes, Controls, Dialogs,
  ExtCtrls, Forms, Graphics, Spin, StdCtrls, SysUtils, TypInfo,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF FPC} LResources, LCLIntf, {$ENDIF}
  RXXPackerProc, KM_Defaults, KM_Log, KM_Pics, KM_ResPalettes, KM_ResSprites;


type
  TRXXPackData = record
    Name: String;
    Id: Integer;
  end;

  TRXXForm1 = class(TForm)
    btnPackRXX: TButton;
    ListBox1: TListBox;
    Label1: TLabel;
    btnUpdateList: TButton;
    procedure btnPackRXXClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnUpdateListClick(Sender: TObject);
  private
    fPalettes: TKMResPalettes;
    fRxxPacker: TRXXPacker;
    fPacksData: array of TRXXPackData;
    fPacksCnt: Integer;

    function AddPackData(aName: String; aId: Integer): TRXXPackData;

    procedure UpdateList;
  end;


var
  RXXForm1: TRXXForm1;


implementation
{$R *.dfm}
uses KM_ResHouses, KM_ResUnits, KM_Points;


function TRXXForm1.AddPackData(aName: String; aId: Integer): TRXXPackData;
begin
  Result.Name := aName;
  Result.Id := aId;
  Inc(fPacksCnt);
  SetLength(fPacksData, fPacksCnt);
  fPacksData[fPacksCnt - 1] := Result;
end;


procedure TRXXForm1.UpdateList;
var
  RT: TRXType;
  PackData: TRXXPackData;
begin
  ListBox1.Items.Clear;
  fPacksCnt := 0;
  SetLength(fPacksData, fPacksCnt);
  for RT := Low(TRXType) to High(TRXType) do
    if (RT = rxTiles) //Tiles are always in the list
      or FileExists(ExeDir + 'SpriteResource\' + RXInfo[RT].FileName + '.rx') then
    begin
      PackData := AddPackData(GetEnumName(TypeInfo(TRXType), Integer(RT)), Integer(RT));
      ListBox1.Items.Add(PackData.Name);
    end;

  if ListBox1.Items.Count = 0 then
  begin
    ShowMessage('No .RX file was found in'+#10+ExeDir + 'SpriteResource\');
    btnPackRXX.Enabled := false;
  end
  else
  begin
    btnPackRXX.Enabled := true;
    ListBox1.ItemIndex := 0;
    ListBox1.SelectAll;
  end;
end;


procedure TRXXForm1.btnUpdateListClick(Sender: TObject);
begin
  btnUpdateList.Enabled := false;

  UpdateList;

  btnUpdateList.Enabled := true;
end;

procedure TRXXForm1.FormCreate(Sender: TObject);
begin
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  Caption := 'RXX Packer (' + GAME_REVISION + ')';

  //Although we don't need them in this tool, these are required to load sprites
  gLog := TKMLog.Create(ExeDir + 'RXXPacker.log');

  fRXXPacker := TRXXPacker.Create;
  fPalettes := TKMResPalettes.Create;
  fPalettes.LoadPalettes(ExeDir + 'data\gfx\');

  fPacksCnt := 0;
  SetLength(fPacksData, 0);

  UpdateList;
end;


procedure TRXXForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fPalettes);
  FreeAndNil(gLog);
  FreeAndNil(fRXXPacker);
end;


procedure TRXXForm1.btnPackRXXClick(Sender: TObject);
var
  RT: TRXType;
  I: Integer;
  Tick: Cardinal;
begin
  btnPackRXX.Enabled := False;
  Tick := GetTickCount;

  Assert(DirectoryExists(ExeDir + 'SpriteResource\'),
         'Cannot find ' + ExeDir + 'SpriteResource\ folder.'+#10#13+
         'Please make sure this folder exists.');

  for I := 0 to ListBox1.Items.Count - 1 do
    if ListBox1.Selected[I] then
    begin
      RT := TRXType(fPacksData[I].Id);

      fRxxPacker.Pack(RT, fPalettes);

      ListBox1.Selected[I] := False;
      ListBox1.Refresh;
    end;

  Label1.Caption := IntToStr(GetTickCount - Tick) + ' ms';
  btnPackRXX.Enabled := True;
end;


{$IFDEF FPC}
initialization
  {$i RXXPackerForm.lrs}
{$ENDIF}


end.

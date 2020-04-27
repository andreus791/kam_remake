unit KM_GUIMapEdTerrainTiles;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, SysUtils,
  KM_InterfaceDefaults,
  KM_Controls, KM_Defaults, KM_Pics;


const
  //Tile table sizes
  MAPED_TILES_X = 6;
  MAPED_TILES_Y = 8;
  TABLE_ELEMS = 496;

type
  TKMMapEdTerrainTiles = class (TKMMapEdSubMenuPage)
  private
    fLastTile: Word;

    procedure TilesChange(Sender: TObject);
    procedure TilesSet(aIndex: Integer);
    procedure TilesRefresh(Sender: TObject);
    function GetTileTexIDFromTag(aTag: Byte; aScrollPosition: Integer = -1): Word;
    function IsTileVisible(aTextId: Integer): Boolean;
    procedure TilesPalette_CloseUpd(Sender: TObject);
  protected
    Panel_Tiles: TKMPanel;
      TilesTable: array [0..MAPED_TILES_X * MAPED_TILES_Y - 1] of TKMButtonFlat; //how many are visible?
      TilesScroll: TKMScrollBar;
      TilesRandom: TKMCheckBox;
      TilesMagicWater, TilesEyedropper, TilesRotate: TKMButtonFlat;
      NumEdit_SetTileNumber: TKMNumericEdit;
    TilesPalette_Button:  TKMButtonFlat;
    Panel_TilesPalettePopup: TKMPopUpPanel;
      Panel_TilesPalette: TKMScrollPanel;
        TilesPaletteTbl: array [0..TABLE_ELEMS - 1] of TKMButtonFlat;
        TilesPaletteRandom: TKMCheckBox;
        TilesPaletteMagicWater, TilesPaletteEyedropper, TilesPaletteRotate: TKMButtonFlat;
        NumEdit_SetTilePaletteNumber: TKMNumericEdit;
  public
    constructor Create(aParent: TKMPanel);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);

    procedure TilesTableSetTileTexId(aTexId: Integer);
    procedure Show;
    procedure Hide;
    procedure UpdateState;
    function Visible: Boolean; override;
    function IsFocused: Boolean; override;
  end;


implementation
uses
  KM_Resource, KM_ResFonts, KM_ResTexts, KM_ResTileset, KM_ResKeys,
  KM_GameCursor, KM_RenderUI, KM_InterfaceGame,
  KM_Utils;

const
  PAL_1ST_ROW = 29; // Ends at the end of stones
  //Tiles table was initially made by JBSnorro, thanks to him :)
  MapEdTileRemap: array [0..TABLE_ELEMS - 1] of Integer = (
     1,73,74,75, 37, 21, 22, 38, 33, 34, 32,181,173,177,129,130,131,132,133,  0,274,270,269,267,268,271,272,273,303, 49,193,197,217,225,  0,  0, 45, 24, 13, 23,208,224, 26,216,  8,  0, 351,352,353,471,472,358,360,362,363,366,369,390,391,477,392,394,
    27,76,77,78, 36, 39, 40,198,100,101,102,189,169,185,134,135,136,137,138,275,283,279,278,276,277,280,281,282,304,124,125,126,229,218,219,220, 46, 11,  5,  0,195, 25,203,207,301,  0, 354,355,356,357,  0,359,361,365,364,367,368,473,474,  0,393,395,
    28,79,80,81, 35, 88, 89, 90, 70, 71, 72,182,174,178,196,139,140,141,142,302,  0,309,310,  0,  0,311,312,  0,  0,127,128,  0,230,226,227,228, 47,204,205,206,199,200,265,266, 16,  0, 370,371,  0,375,377,381,382,383,384,386,388,396,397,398,399,401,
    29,82,83,84, 85, 86, 87,  0,112,113,114,109,110,111,161,162,163,164,165,  0,291,287,286,284,285,288,289,290,305,106,107,108,233,234,231,  0, 48,221,213,214,458,385,459,347,348,349, 372,373,374,376,378,379,380,468,469,387,389,475,476,  0,400,402,
    30,94,95,96, 57, 58, 59,  0,103,104,105,183,175,179,157,202,158,159,160,300,299,295,294,292,293,296,297,298,306,117,118,119,209,210,241,245,194,248, 65, 66,460,461,462,166, 51, 54, 403,404,405,406,407,464,466,426,427,428,430,440,441,442,445,447,
    31, 9,19,20, 41, 42, 43, 44,320,321,322,191,171,187,149,150,260,151,152,261,323,324,325,332,333,334,341,342,343,242,243,244,235,238,239,240,  0, 50,172, 52,257,258,259,246,232,  0, 408,409,410,411,  0,465,467,424,425,429,431,443,444,  0,446,448,
    18,67,68,69, 91, 92, 93,  0,  6,  7, 10,184,176,180,145,146,147,148,308,  0,326,327,328,335,336,337,344,345,346,115,116,120,236,237,143,144,  0, 53,167, 55,262,263,307,223,222,247, 433,432,  0,436,438,412,413,414,415,420,422,450,451,449,454,456,
    17,97,98,99, 12, 14, 15,  0,  3,  4,  2,192,168,188,153,154,155,156,264,  0,329,330,331,338,339,340,  0,  0,  0,121,122,123,211,212,201,  0,316,317,318,319,313,314,315,215,350,463, 434,435,470,437,439,416,417,418,419,421,423,452,453,  0,455,457
    );
    // 247 - doesn't work in game, replaced with random road

var
  TABLE_ELEMS_CNT: Integer;


constructor TKMMapEdTerrainTiles.Create(aParent: TKMPanel);
const
  BTN_SIZE_S = 34;
  BTN_SIZE = 36;
  PAL_S = 34;

  TB_TLS_M = 9;
  TB_TLS_R = 9;
  TB_TLS_S = 13;
  TB_TLS_T = 13;
var
  J,K,X,Y,row,TexID,palH: Integer;
begin
  inherited Create;

//  TABLE_ELEMS_CNT := Ceil(TILES_CNT / MAPED_TILES_Y) * MAPED_TILES_Y;
  TABLE_ELEMS_CNT := TABLE_ELEMS;

  Panel_Tiles := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);
  with TKMLabel.Create(Panel_Tiles, 0, TERRAIN_PAGE_TITLE_Y, Panel_Tiles.Width, 0, gResTexts[TX_MAPED_TERRAIN_HINTS_TILES], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];

  TilesMagicWater := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_M, 25, BTN_SIZE_S, BTN_SIZE_S, 670);
  TilesMagicWater.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_MAGIC_WATER_HINT, SC_MAPEDIT_SUB_MENU_ACTION_1);
  TilesMagicWater.OnClick := TilesChange;

  TilesEyedropper := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_M + BTN_SIZE_S + 2, 25, BTN_SIZE_S, BTN_SIZE_S, 671);
  TilesEyedropper.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_EYEDROPPER_HINT, SC_MAPEDIT_SUB_MENU_ACTION_2);
  TilesEyedropper.OnClick := TilesChange;

  TilesRotate := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_R + 2*BTN_SIZE_S + 4, 25, BTN_SIZE_S, BTN_SIZE_S, 672);
  TilesRotate.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_ROTATE_TILE, SC_MAPEDIT_SUB_MENU_ACTION_3);
  TilesRotate.OnClick := TilesChange;

  NumEdit_SetTileNumber := TKMNumericEdit.Create(Panel_Tiles, Panel_Tiles.Width - 73, 29, 0, MAX_TILE_TO_SHOW - 1);
  NumEdit_SetTileNumber.Anchors := [anTop, anRight];
  NumEdit_SetTileNumber.Hint := gResTexts[TX_MAPED_TERRAIN_TILE_ID_EDIT_HINT];
  NumEdit_SetTileNumber.OnChange := TilesChange;
  NumEdit_SetTileNumber.AutoFocusable := False;

  TilesRandom := TKMCheckBox.Create(Panel_Tiles, TB_TLS_R, 25 + BTN_SIZE + 5, Panel_Tiles.Width - TB_TLS_R, 20, gResTexts[TX_MAPED_TERRAIN_TILES_RANDOM], fntMetal);
  TilesRandom.Checked := True;
  TilesRandom.OnClick := TilesChange;
  TilesRandom.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_TILES_RANDOM_HINT, SC_MAPEDIT_SUB_MENU_ACTION_4);

  //Create scroll first to link to its MouseWheel event
  TilesScroll := TKMScrollBar.Create(Panel_Tiles, TB_TLS_S, 23 + BTN_SIZE + 28 + 4 + MAPED_TILES_Y * 32, 194, 20, saHorizontal, bsGame);
  TilesScroll.MaxValue := (TABLE_ELEMS_CNT div MAPED_TILES_Y) - MAPED_TILES_X; // 32 - 6
  TilesScroll.Position := 0;
  TilesScroll.OnChange := TilesRefresh;

  for J := 0 to MAPED_TILES_Y - 1 do
    for K := 0 to MAPED_TILES_X - 1 do
    begin
      TilesTable[J * MAPED_TILES_X + K] := TKMButtonFlat.Create(Panel_Tiles, TB_TLS_T + K * 32, 23 + BTN_SIZE + 28 + J * 32, 32, 32, 1, rxTiles);
      TilesTable[J * MAPED_TILES_X + K].Tag :=  J * MAPED_TILES_X + K; //Store ID
      TilesTable[J * MAPED_TILES_X + K].OnClick := TilesChange;
      TilesTable[J * MAPED_TILES_X + K].OnMouseWheel := TilesScroll.MouseWheel;
    end;

  TilesPalette_Button := TKMButtonFlat.Create(Panel_Tiles, 9, 23 + BTN_SIZE + 28 + 4 + MAPED_TILES_Y * 32 + 25, Panel_Tiles.Width - 9, 21, 0);
  TilesPalette_Button.Anchors := [anLeft, anTop, anRight];
  TilesPalette_Button.Caption := gResTexts[TX_MAPED_TERRAIN_TILES_PALETTE];
  TilesPalette_Button.CapOffsetY := -11;
  TilesPalette_Button.Hint := GetHintWHotKey(TX_MAPED_TERRAIN_TILES_PALETTE, SC_MAPEDIT_TILES_PALETTE);
  TilesPalette_Button.OnClick := TilesPalette_CloseUpd;

  palH := 2*MAPED_TILES_Y*PAL_S + 15;

  Panel_TilesPalettePopup := TKMPopUpPanel.Create(aParent.MasterControl.MasterPanel, 1000, palH + 10, gResTexts[TX_MAPED_TERRAIN_TILES_PALETTE],
                                                  pubgitScrollWCross, True, False);
  Panel_TilesPalettePopup.DragEnabled := True;
  Panel_TilesPalettePopup.CapOffsetY := -15;
    Panel_TilesPalette := TKMScrollPanel.Create(Panel_TilesPalettePopup, 5, 5, 990, palH, [saHorizontal, saVertical], bsGame, ssGame);
      row := TABLE_ELEMS div MAPED_TILES_Y;
      for J := 0 to MAPED_TILES_Y - 1 do
        for K := 0 to row - 1 do
        begin
          X := ((K mod PAL_1ST_ROW) + (K div PAL_1ST_ROW)*(((2*PAL_1ST_ROW - row) div 2) + 2)) * PAL_S;
          Y := (J + MAPED_TILES_Y*(K div PAL_1ST_ROW)) * PAL_S + 5*(K div PAL_1ST_ROW);
          TexID := MapEdTileRemap[J * row + K];
          TilesPaletteTbl[J * row + K] := TKMButtonFlat.Create(Panel_TilesPalette, X, Y, 32, 32, TexID, rxTiles);
          TilesPaletteTbl[J * row + K].Tag :=  J * row + K; //Store ID
          TilesPaletteTbl[J * row + K].Clickable := TexID <> 0;
          TilesPaletteTbl[J * row + K].HideHighlight := TexID = 0;
          TilesPaletteTbl[J * row + K].OnClick := TilesChange;
          if TexID = 0 then
            TilesPaletteTbl[J * row + K].Hint := ''
          else
            //Show 0..N-1 to be consistent with objects and script commands like States.MapTileObject
            TilesPaletteTbl[J * row + K].Hint := IntToStr(TexID - 1);
        end;

      TilesPaletteMagicWater := TKMButtonFlat.Create(Panel_TilesPalette, 0, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 670);
      TilesPaletteMagicWater.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_MAGIC_WATER_HINT, SC_MAPEDIT_SUB_MENU_ACTION_1);
      TilesPaletteMagicWater.OnClick := TilesChange;

      TilesPaletteEyedropper := TKMButtonFlat.Create(Panel_TilesPalette, BTN_SIZE_S + 2, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 671);
      TilesPaletteEyedropper.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_EYEDROPPER_HINT, SC_MAPEDIT_SUB_MENU_ACTION_2);
      TilesPaletteEyedropper.OnClick := TilesChange;

      TilesPaletteRotate := TKMButtonFlat.Create(Panel_TilesPalette, 2*BTN_SIZE_S + 4, (MAPED_TILES_Y + 1)*PAL_S, BTN_SIZE_S, BTN_SIZE_S, 672);
      TilesPaletteRotate.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_ROTATE_TILE, SC_MAPEDIT_SUB_MENU_ACTION_3);
      TilesPaletteRotate.OnClick := TilesChange;

      NumEdit_SetTilePaletteNumber := TKMNumericEdit.Create(Panel_TilesPalette, 3*BTN_SIZE_S + 25, (MAPED_TILES_Y + 1)*PAL_S + ((PAL_S - 20) div 2), 0, MAX_TILE_TO_SHOW - 1);
      NumEdit_SetTilePaletteNumber.Anchors := [anTop, anRight];
      NumEdit_SetTilePaletteNumber.Hint := gResTexts[TX_MAPED_TERRAIN_TILE_ID_EDIT_HINT];
      NumEdit_SetTilePaletteNumber.OnChange := TilesChange;
      NumEdit_SetTilePaletteNumber.AutoFocusable := False;

      TilesPaletteRandom := TKMCheckBox.Create(Panel_TilesPalette, 0, (MAPED_TILES_Y + 1)*PAL_S + BTN_SIZE + 5, Panel_Tiles.Width - TB_TLS_R, 20, gResTexts[TX_MAPED_TERRAIN_TILES_RANDOM], fntMetal);
      TilesPaletteRandom.Checked := True;
      TilesPaletteRandom.OnClick := TilesChange;
      TilesPaletteRandom.Hint := GetHintWHotkey(TX_MAPED_TERRAIN_TILES_RANDOM_HINT, SC_MAPEDIT_SUB_MENU_ACTION_4);


  fSubMenuActionsEvents[0] := TilesChange;
  fSubMenuActionsEvents[1] := TilesChange;
  fSubMenuActionsEvents[2] := TilesChange;
  fSubMenuActionsEvents[3] := TilesChange;

  fSubMenuActionsCtrls[0,0] := TilesMagicWater;
  fSubMenuActionsCtrls[1,0] := TilesEyedropper;
  fSubMenuActionsCtrls[2,0] := TilesRotate;
  fSubMenuActionsCtrls[3,0] := TilesRandom;

  fSubMenuActionsCtrls[0,1] := TilesPaletteMagicWater;
  fSubMenuActionsCtrls[1,1] := TilesPaletteEyedropper;
  fSubMenuActionsCtrls[2,1] := TilesPaletteRotate;
  fSubMenuActionsCtrls[3,1] := TilesPaletteRandom;
end;


procedure TKMMapEdTerrainTiles.TilesChange(Sender: TObject);
var
  isMagicWater, isEyedropper, isRotate, isRandom, isTileNum: Boolean;
  value: Integer;
begin
  isMagicWater := (Sender = TilesMagicWater) or (Sender = TilesPaletteMagicWater);
  isEyedropper := (Sender = TilesEyedropper) or (Sender = TilesPaletteEyedropper);
  isRotate     := (Sender = TilesRotate) or (Sender = TilesPaletteRotate);
  isRandom     := (Sender = TilesRandom) or (Sender = TilesPaletteRandom);
  isTileNum    := (Sender = NumEdit_SetTileNumber) or (Sender = NumEdit_SetTilePaletteNumber);

  // Do not hide palette on random check
  if not isRandom and not isTileNum then
    Panel_TilesPalettePopup.Hide;

  TilesMagicWater.Down := isMagicWater and not TilesMagicWater.Down;
  TilesPaletteMagicWater.Down := TilesMagicWater.Down;

  TilesEyedropper.Down := isEyedropper and not TilesEyedropper.Down;
  TilesPaletteEyedropper.Down := TilesEyedropper.Down;

  TilesRotate.Down := isRotate and not TilesRotate.Down;
  TilesPaletteRotate.Down := TilesRotate.Down;

  if isMagicWater then
  begin
    if TilesMagicWater.Down then
      gGameCursor.Mode := cmMagicWater
    else
      gGameCursor.Mode := cmNone;
  end else

  if isEyedropper then
  begin
    if TilesEyedropper.Down then
      gGameCursor.Mode := cmEyedropper
    else
      gGameCursor.Mode := cmNone;
  end else

  if isRotate then
  begin
    if TilesRotate.Down then
      gGameCursor.Mode := cmRotateTile
    else
      gGameCursor.Mode := cmNone;
  end else

  if isRandom then
    gGameCursor.MapEdDir := 4 * Byte(TKMCheckBox(Sender).Checked) //Defined=0..3 or Random=4
  else

  if isTileNum then
  begin
    value := TKMNumericEdit(Sender).Value;
    NumEdit_SetTileNumber.Value := value;
    NumEdit_SetTilePaletteNumber.Value := value;

    if gRes.Tileset.TileIsAllowedToSet(value) then
    begin
      TilesSet(value + 1);
      TilesTableSetTileTexId(value);
    end
  end else

  if (Sender is TKMButtonFlat)
    and not (Sender = TilesMagicWater)
    and not (Sender = TilesRotate)
    and not (Sender = TilesEyedropper) then
  begin
    TilesSet(TKMButtonFlat(Sender).TexID);
    NumEdit_SetTileNumber.Value := TKMButtonFlat(Sender).TexID - 1;
    NumEdit_SetTilePaletteNumber.Value := TKMButtonFlat(Sender).TexID - 1;
  end;

  // Refresh immidiately
  TilesRefresh(nil);
end;


procedure TKMMapEdTerrainTiles.TilesPalette_CloseUpd(Sender: TObject);
begin
  Panel_TilesPalettePopup.ToggleVisibility;
end;


function TKMMapEdTerrainTiles.IsTileVisible(aTextId: Integer): Boolean;
var
  I,K,RowStart: Integer;
begin
  Result := False;
  for I := 0 to MAPED_TILES_Y - 1 do
  begin
    RowStart := I * (TABLE_ELEMS_CNT div MAPED_TILES_Y) + TilesScroll.Position;
    for K := RowStart to RowStart + MAPED_TILES_X - 1 do
      if MapEdTileRemap[K] = aTextId + 1 then
      begin
        Result := True;
        Exit;
      end;
  end;

end;


procedure TKMMapEdTerrainTiles.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  if aHandled then Exit;

  if (Key = VK_ESCAPE) and Panel_TilesPalettePopup.Visible then
  begin
    Panel_TilesPalettePopup.Hide;
    aHandled := True;
  end
  else
  if Key = gResKeys[SC_MAPEDIT_TILES_PALETTE].Key then
  begin
    Panel_TilesPalettePopup.ToggleVisibility;
    aHandled := True;
  end;
end;


procedure TKMMapEdTerrainTiles.TilesTableSetTileTexId(aTexId: Integer);
var
  I,K,L,SP: Integer;
begin
  NumEdit_SetTileNumber.Value := aTexId;
  NumEdit_SetTilePaletteNumber.Value := aTexId;

  if not IsTileVisible(aTexId) then
    for SP := 0 to TilesScroll.MaxValue do
      for I := 0 to MAPED_TILES_Y - 1 do
        for K := 0 to MAPED_TILES_X - 1 do
        begin
          L := I * MAPED_TILES_X + K;
          if aTexId = GetTileTexIDFromTag(L, SP) - 1 then
          begin
            if TilesScroll.Position = SP then
              Exit;
            TilesScroll.Position := SP;
            TilesRefresh(nil);
            Exit;
          end;
        end;
end;


procedure TKMMapEdTerrainTiles.TilesSet(aIndex: Integer);
begin
  TilesMagicWater.Down := False;
//  TilesEyedropper.Down := False;
  if aIndex <> 0 then
  begin
    gGameCursor.Mode := cmTiles;
    gGameCursor.Tag1 := aIndex - 1; //MapEdTileRemap is 1 based, tag is 0 based

    if TilesRandom.Checked then
      gGameCursor.MapEdDir := 4;

    //Remember last selected Tile
    fLastTile := aIndex;
  end;

  TilesRefresh(nil);
end;


function TKMMapEdTerrainTiles.GetTileTexIDFromTag(aTag: Byte; aScrollPosition: Integer = -1): Word;
var X,Y: Byte;
  Tile: Word;
  ScrollPosition: Integer;
begin
  ScrollPosition := IfThen(aScrollPosition = -1, TilesScroll.Position, aScrollPosition);

  X := aTag mod MAPED_TILES_X + ScrollPosition;
  Y := (aTag div MAPED_TILES_X);
  Tile := (TABLE_ELEMS_CNT div MAPED_TILES_Y) * Y + X;
//  if Tile > TILES_CNT then
//    Result := 0;

  Result := MapEdTileRemap[Tile];
end;


procedure TKMMapEdTerrainTiles.TilesRefresh(Sender: TObject);
var
  I,K,L: Integer;
  TileTexID, row: Integer;
begin
  TilesRandom.Checked  := (gGameCursor.MapEdDir = 4);
  TilesMagicWater.Down := gGameCursor.Mode = cmMagicWater;
  TilesEyedropper.Down := gGameCursor.Mode = cmEyedropper;
  TilesRotate.Down     := gGameCursor.Mode = cmRotateTile;

  TilesPaletteRandom.Checked  := TilesRandom.Checked;
  TilesPaletteMagicWater.Down := TilesMagicWater.Down;
  TilesPaletteEyedropper.Down := TilesEyedropper.Down;
  TilesPaletteRotate.Down     := TilesRotate.Down;

  for I := 0 to MAPED_TILES_Y - 1 do
  for K := 0 to MAPED_TILES_X - 1 do
  begin
    L := I * MAPED_TILES_X + K;
    TileTexID := GetTileTexIDFromTag(L);
    TilesTable[L].TexID := TileTexID;
    //Don't disable it because then scrollwheel doesn't work
    TilesTable[L].HideHighlight := TileTexID = 0;
    TilesTable[L].Clickable := TileTexID <> 0;
    if TileTexID = 0 then
      TilesTable[L].Hint := ''
    else
      //Show 0..N-1 to be consistent with objects and script commands like States.MapTileObject
      TilesTable[L].Hint := IntToStr(TileTexID - 1);
    //If cursor has a tile then make sure its properly selected in table as well
    TilesTable[L].Down := (gGameCursor.Mode in [cmTiles, cmEyedropper]) and (gGameCursor.Tag1 = TileTexID - 1);
  end;

  row := TABLE_ELEMS div MAPED_TILES_Y;
  for I := 0 to MAPED_TILES_Y - 1 do
    for K := 0 to row - 1 do
      TilesPaletteTbl[I * row + K].Down := (gGameCursor.Mode in [cmTiles, cmEyedropper]) and (gGameCursor.Tag1 = MapEdTileRemap[I * row + K] - 1)
end;


procedure TKMMapEdTerrainTiles.Show;
begin
  TilesSet(fLastTile);
  gGameCursor.MapEdDir := 0;
  Panel_Tiles.Show;
end;


function TKMMapEdTerrainTiles.Visible: Boolean;
begin
  Result := Panel_Tiles.Visible;
end;


function TKMMapEdTerrainTiles.IsFocused: Boolean;
begin
  Result := Visible or Panel_TilesPalettePopup.Visible;
end;


procedure TKMMapEdTerrainTiles.Hide;
begin
  Panel_Tiles.Hide;
end;


procedure TKMMapEdTerrainTiles.UpdateState;
begin
  TilesRefresh(nil);
end;


end.

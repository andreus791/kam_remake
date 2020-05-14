unit KM_RenderDebug;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonClasses, Generics.Collections,
  KM_MarchingSquares, KM_Viewport, KM_AIDefensePos;

type
  TKMDefPosData = class;

  TKMRenderDebug = class
  private
    fAreaTilesLand: TBoolean2Array;
    procedure ResetAreaLand;
    procedure CollectAreaTiles(var aPoints: TBoolean2Array; const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single;
                               aDistanceFunc: TCoordDistanceFn);
  public
    procedure ReInit;

    procedure PaintMiningRadius;
    procedure PaintDefences;

    procedure RenderTiledArea(const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single; aDistanceFunc: TCoordDistanceFn;
                                    aFillColor, aLineColor: Cardinal);
  end;


  TKMDefPosData = class(TInterfacedObject, IKMData2D<Boolean>)
  private
    fAreaPoints: TBoolean2Array;
    function GetData(X, Y: Integer): Boolean;
  public
    constructor Create(var aDefPoints: TBoolean2Array);
  end;


implementation
uses
  Math, SysUtils, KromUtils,
  KM_Game, KM_RenderAux, KM_RenderUI, KM_Pics,
  KM_Resource, KM_Terrain, KM_Houses, KM_HouseWoodcutters, KM_ResHouses, KM_ResWares, KM_ResUnits,
  KM_HandsCollection, KM_CommonUtils, KM_RenderPool, KM_Utils;


{ TKMRenderDebug }
procedure TKMRenderDebug.ReInit;
begin
  SetLength(fAreaTilesLand, gTerrain.MapY, gTerrain.MapX);
end;


// Render quads over tiles
procedure TKMRenderDebug.RenderTiledArea(const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single; aDistanceFunc: TCoordDistanceFn;
                                               aFillColor, aLineColor: Cardinal);
var
  I, K: Integer;
  borderPoints: TList<TKMPointList>;
  defPosData: TKMDefPosData;
  marchingSquares: TKMMarchingSquares;
begin
  ResetAreaLand;
  borderPoints := TObjectList<TKMPointList>.Create; // Object list will take care of Freeing added objects
  defPosData := TKMDefPosData.Create(fAreaTilesLand);

  marchingSquares := TKMMarchingSquares.Create(defPosData as IKMData2D<Boolean>, gTerrain.MapX + 1, gTerrain.MapY + 1);

  try
    for I := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
      for K := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
        if InRange(aDistanceFunc(K, I), aMinRadius, aMaxRadius) and gTerrain.TileInMapCoords(aLoc.X+K, aLoc.Y+I) then
        begin
          fAreaTilesLand[aLoc.Y+I - 1, aLoc.X+K - 1] := True; // fDefLand is 0-based
          gRenderAux.Quad(aLoc.X+K, aLoc.Y+I, aFillColor);
        end;

    if not marchingSquares.IdentifyPerimeters(borderPoints) then
      Exit;

    for K := 0 to borderPoints.Count - 1 do
      gRenderAux.LineOnTerrain(borderPoints[K], aLineColor);
  finally
    marchingSquares.Free;
    borderPoints.Clear;
    borderPoints.Free;
  end;
end;


procedure TKMRenderDebug.CollectAreaTiles(var aPoints: TBoolean2Array; const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single;
                                          aDistanceFunc: TCoordDistanceFn);
var
  I, K: Integer;
begin
  for I := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
    for K := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
      if InRange(aDistanceFunc(K, I), aMinRadius, aMaxRadius) and gTerrain.TileInMapCoords(aLoc.X+K, aLoc.Y+I) then
        aPoints[aLoc.Y+I - 1, aLoc.X+K - 1] := True;
end;


procedure TKMRenderDebug.ResetAreaLand;
var
  I: Integer;
begin
  //Dynamic 2d array should be cleared row by row
  for I := 0 to gTerrain.MapY - 1 do
    FillChar(fAreaTilesLand[I,0], SizeOf(fAreaTilesLand[I,0]) * Length(fAreaTilesLand[I]), #0);
end;


procedure TKMRenderDebug.PaintDefences;
var
  I, J, K: Integer;
  DP: TAIDefencePosition;
  fillColor, lineColor: Cardinal;

  borderPoints: TList<TKMPointList>;
  defPosData: TKMDefPosData;
  marchingSquares: TKMMarchingSquares;
begin
  if SKIP_RENDER or (gGame = nil) then Exit;

  Assert(Length(fAreaTilesLand) > 0, 'TKMRenderDebug was not initialized');

  borderPoints := TObjectList<TKMPointList>.Create; // Object list will take care of Freeing added objects

  defPosData := TKMDefPosData.Create(fAreaTilesLand);
  marchingSquares := TKMMarchingSquares.Create(defPosData as IKMData2D<Boolean>, gTerrain.MapX + 1, gTerrain.MapY + 1);
  try
    //Draw tiles and shared borders first for all players
    for I := 0 to gHands.Count - 1 do
    begin
      borderPoints.Clear;
      ResetAreaLand; //Reset data for every hand

      if I = gMySpectator.SelectedHandID then
      begin
        fillColor := gHands[I].FlagColor and $60FFFFFF;
        lineColor := icCyan;
      end
      else
      begin
        fillColor := gHands[I].FlagColor and $20FFFFFF;
        lineColor := gHands[I].FlagColor;
      end;

      for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
      begin
        DP := gHands[I].AI.General.DefencePositions[K];

        CollectAreaTiles(fAreaTilesLand, DP.Position.Loc, 0, DP.Radius, KMLengthDiag);
      end;

      //Draw quads
      gRenderAux.SetColor(fillColor); //Setting color initially will be much faster, than calling it on every cell
      for J := 0 to gTerrain.MapY - 1 do
        for K := 0 to gTerrain.MapX - 1 do
          if fAreaTilesLand[J, K] then
            gRenderAux.Quad(K + 1, J + 1); //gTerrain is 1-based...

      if not marchingSquares.IdentifyPerimeters(borderPoints) then
        Continue;

      for K := 0 to borderPoints.Count - 1 do
        gRenderAux.LineOnTerrain(borderPoints[K], lineColor);
    end;


    //And all def positions pics - above tiles and borders
    for I := 0 to gHands.Count - 1 do
      for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
      begin
        DP := gHands[I].AI.General.DefencePositions[K];
        //Dir selector
        gRenderPool.RenderSpriteOnTile(DP.Position.Loc, 510 + Byte(DP.Position.Dir), gHands[I].FlagColor);
        //GroupType icon
        gRenderPool.RenderSpriteOnTile(DP.Position.Loc, GROUP_IMG[DP.GroupType], gHands[I].FlagColor);
      end;
  finally
//    defPosData.Free;
    marchingSquares.Free;
    //Clear and Free borderPoints
    borderPoints.Clear;
    borderPoints.Free;
  end;
end;


procedure TKMRenderDebug.PaintMiningRadius;
const
  GOLD_ORE_COLOR = icYellow;
  IRON_ORE_COLOR = icSteelBlue;
  COAL_ORE_COLOR = icGray;
  WOODCUTTER_COLOR = icGreen;
  QUARRY_COLOR = icBlack;
  FISHERHUT_COLOR = icBlue;
  FARM_COLOR = icYellow;
  WINEYARD_COLOR = icLightCyan;
  SELECTED_ORE_COLOR = icLight2Red;

  procedure AddOrePoints(aOreP, aAllOreP: TKMPointListArray);
  var
    I,J,K: Integer;
    Skip: Boolean;
  begin
    for I := 0 to Length(aOreP) - 1 do
    begin
      for J := 0 to aOreP[I].Count - 1 do
      begin
        Skip := False;
        //Skip if we already have this point in upper layer
        for K := 0 to I do
          if aAllOreP[K].Contains(aOreP[I][J]) then
          begin
            Skip := True;
            Break;
          end;
        if not Skip then
        begin
          aAllOreP[I].Add(aOreP[I][J]); //Couild be Add actually, as we checked Contains already
          //Remove added points from lowered layers
          for K := I + 1 to 2 do
            aAllOreP[K].Remove(aOreP[I][J]);
        end;
      end;
    end;
  end;

  procedure PaintOrePoints(aOreP: TKMPointListArray; Color: Cardinal; aHighlight: Boolean = False);
  var
    I, K, L: Integer;
    Color2: Cardinal;
    Coef: Single;
  begin
    Coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      Coef := 0.3;
    end;

    for I := 1 to Length(aOreP) - 1 do
    begin
      Color := Color and $40FFFFFF; //Add some transparency
      Color := MultiplyBrightnessByFactor(Color, Coef);
      for K := Length(aOreP) - 1 downto 0 do
        for L := 0 to aOreP[K].Count - 1 do
        begin
          Color2 := Color;
          if K = 1 then
            Color2 := MultiplyBrightnessByFactor(Color, 4);
          if K = 2 then
            Color2 := MultiplyBrightnessByFactor(Color, 7);
          gRenderAux.Quad(aOreP[K][L].X, aOreP[K][L].Y, Color2);
        end;
    end;
  end;

  procedure PaintMiningPoints(aPoints: TKMPointList; Color: Cardinal; aHighlight: Boolean = False; aDeepCl: Boolean = False);
  var
    I: Integer;
    Coef: Single;
  begin
    Coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      Coef := 0.3;
    end;

    if aDeepCl then
      Color := Color and $80FFFFFF //Add some transparency
    else
      Color := Color and $40FFFFFF; //Add more transparency
    Color := MultiplyBrightnessByFactor(Color, Coef);

    for I := 0 to aPoints.Count - 1 do
      gRenderAux.Quad(aPoints[I].X, aPoints[I].Y, Color);
  end;

var
  I, J, K: Integer;
  H: TKMHouse;
  IronOreP, GoldOreP, CoalOreP, OreP, SelectedOreP: TKMPointListArray;
  WoodcutterPts, QuarryPts, FisherHutPts, FarmPts, WineyardPts: TKMPointList;
  HouseDirPts: TKMPointDirList;
  HousePts, SelectedPts: TKMPointList;
begin
  if gGame = nil then Exit;

  SetLength(OreP, 3);
  SetLength(IronOreP, 3);
  SetLength(GoldOreP, 3);
  SetLength(CoalOreP, 3);
  SetLength(SelectedOreP, 3);

  for I := 0 to Length(OreP) - 1 do
  begin
    OreP[I] := TKMPointList.Create;
    IronOreP[I] := TKMPointList.Create;
    GoldOreP[I] := TKMPointList.Create;
    CoalOreP[I] := TKMPointList.Create;
    SelectedOreP[I] := TKMPointList.Create;
  end;

  WoodcutterPts := TKMPointList.Create;
  QuarryPts := TKMPointList.Create;
  FisherHutPts := TKMPointList.Create;
  FarmPts := TKMPointList.Create;
  WineyardPts := TKMPointList.Create;
  HousePts := TKMPointList.Create;
  HouseDirPts := TKMPointDirList.Create;
  SelectedPts := TKMPointList.Create;

  for I := 0 to gHands.Count - 1 do
  begin
    for J := 0 to gHands[I].Houses.Count - 1 do
    begin
      HousePts.Clear;
      HouseDirPts.Clear;
      H := gHands[I].Houses[J];
      case H.HouseType of
        htIronMine:   begin
                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtIronOre, OreP);
                        AddOrePoints(OreP, IronOreP);
                      end;
        htGoldMine:   begin
                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtGoldOre, OreP);
                        AddOrePoints(OreP, GoldOreP);
                      end;
        htCoalMine:   begin
                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtCoal, OreP);
                        AddOrePoints(OreP, CoalOreP);
                      end;
        htWoodcutters:begin
                        gTerrain.FindPossibleTreePoints(TKMHouseWoodcutters(H).FlagPoint,
                                                        gRes.Units[utWoodcutter].MiningRange,
                                                        HousePts);
                        WoodcutterPts.AddList(HousePts);
                      end;
        htQuary:      begin
                        gTerrain.FindStoneLocs(H.PointBelowEntrance,
                                               gRes.Units[utStoneCutter].MiningRange,
                                               KMPOINT_ZERO, True, HousePts);
                        QuarryPts.AddList(HousePts);
                      end;
        htFisherHut:  begin
                        gTerrain.FindFishWaterLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFisher].MiningRange,
                                                   KMPOINT_ZERO, True, HouseDirPts);
                        HouseDirPts.ToPointList(HousePts, True);
                        FisherHutPts.AddList(HousePts);
                      end;
        htFarm:       begin
                        gTerrain.FindCornFieldLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFarmer].MiningRange,
                                                   HousePts);
                        FarmPts.AddList(HousePts);
                      end;
        htWineyard:   begin
                        gTerrain.FindWineFieldLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFarmer].MiningRange,
                                                   HousePts);
                        WineyardPts.AddList(HousePts);
                      end;
        else Continue;
      end;

      if gMySpectator.Selected = H then
      begin
        if H.HouseType in [htIronMine, htGoldMine, htCoalMine] then
        begin
          for K := 0 to Length(OreP) - 1 do
            SelectedOreP[K].AddList(OreP[K]);
        end
        else
          SelectedPts.AddList(HousePts);
      end;

      for K := 0 to Length(OreP) - 1 do
        OreP[K].Clear;
    end;
  end;

  PaintOrePoints(IronOreP, IRON_ORE_COLOR);
  PaintOrePoints(GoldOreP, GOLD_ORE_COLOR);
  PaintOrePoints(CoalOreP, COAL_ORE_COLOR);
  PaintOrePoints(SelectedOreP, 0, True);

  PaintMiningPoints(WoodcutterPts, WOODCUTTER_COLOR);
  PaintMiningPoints(QuarryPts, QUARRY_COLOR);
  PaintMiningPoints(FisherHutPts, FISHERHUT_COLOR);
  PaintMiningPoints(FarmPts, FARM_COLOR, False, True);
  PaintMiningPoints(WineyardPts, WINEYARD_COLOR);
  PaintMiningPoints(SelectedPts, 0, True);

  for I := 0 to Length(OreP) - 1 do
  begin
    OreP[I].Free;
    IronOreP[I].Free;
    GoldOreP[I].Free;
    CoalOreP[I].Free;
    SelectedOreP[I].Free;
  end;
  WoodcutterPts.Free;
  QuarryPts.Free;
  FisherHutPts.Free;
  FarmPts.Free;
  WineyardPts.Free;
  HousePts.Free;
  HouseDirPts.Free;
  SelectedPts.Free;
end;



{ TKMDefPosData }
constructor TKMDefPosData.Create(var aDefPoints: TBoolean2Array);
begin
  inherited Create;

  fAreaPoints := aDefPoints;
end;


function TKMDefPosData.GetData(X, Y: Integer): Boolean;
begin
  Result :=     InRange(Y, Low(fAreaPoints), High(fAreaPoints))
            and InRange(X, Low(fAreaPoints[Y]), High(fAreaPoints[Y]))
            and fAreaPoints[Y, X];
end;


end.
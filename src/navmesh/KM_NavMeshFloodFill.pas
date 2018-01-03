unit KM_NavMeshFloodFill;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_CommonTypes, KM_Points;

type
  TPolygonQueue = record
    Visited: Byte;
    Distance, Next: Word;
    DistPoint: TKMPoint;
  end;

  // Flood-Fill with queue
  TNavMeshFloodFill = class
  private
    fVisitedIdx: Byte;
  protected
    fSorted: Boolean; // Only for sorted case
    fStartQueue, fEndQueue, fQueueCnt: Word;
    fQueueArray: array of TPolygonQueue; // max 2000 elements (polygons in navmesh) -> use array with fixed length instead of creating elements which have 10<->20 bytes

    procedure MakeNewQueue(); virtual;
    procedure ClearVisitIdx();
    function IsQueueEmpty(): Boolean; inline;
    function IsVisited(const aIdx: Word): Boolean; inline;
    function CanBeVisited(const aIdx: Word): Boolean; virtual;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); virtual;
    procedure InsertInQueue(const aIdx: Word); virtual;
    procedure InsertAndSort(const aIdx: Word); virtual; // Only for sorted case
    function RemoveFromQueue(var aIdx: Word): Boolean;

    procedure InitQueue(const aMaxIdx: Word; aInitIdxArray: TKMWordArray); virtual;
    procedure Flood(); virtual;
  public
    constructor Create(aSorted: Boolean = False);
    destructor Destroy(); override;

    function FillPolygons(const aMaxIdx: Word; aInitIdxArray: TKMWordArray): Boolean; virtual;
  end;


implementation
uses
  KM_AIFields, KM_NavMesh;

{ TNavMeshPathFinding }
constructor TNavMeshFloodFill.Create(aSorted: Boolean = False);
begin
  fQueueCnt := 0;
  fStartQueue := 0;
  fEndQueue := 0;
  fVisitedIdx := 0;
  fSorted := aSorted;
  inherited Create();
end;


destructor TNavMeshFloodFill.Destroy();
begin
  inherited;
end;


procedure TNavMeshFloodFill.MakeNewQueue();
begin
  fVisitedIdx := fVisitedIdx + 1;
  if (Length(fQueueArray) < Length(gAIFields.NavMesh.Polygons)) then
  begin
    SetLength(fQueueArray, Length(gAIFields.NavMesh.Polygons));
    ClearVisitIdx();
  end;
  if (fVisitedIdx = High(Byte)) then
    ClearVisitIdx();
end;


procedure TNavMeshFloodFill.ClearVisitIdx();
var
  I: Word;
begin
  fVisitedIdx := 1;
  for I := Low(fQueueArray) to High(fQueueArray) do
    fQueueArray[I].Visited := 0;
end;


function TNavMeshFloodFill.IsQueueEmpty(): Boolean;
begin
  Result := fQueueCnt = 0;
end;


function TNavMeshFloodFill.IsVisited(const aIdx: Word): Boolean;
begin
  Result := (fQueueArray[aIdx].Visited = fVisitedIdx);
end;


function TNavMeshFloodFill.CanBeVisited(const aIdx: Word): Boolean;
begin
  Result := True;
end;


procedure TNavMeshFloodFill.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
begin
  with fQueueArray[aIdx] do
  begin
    Visited := fVisitedIdx;
    DistPoint := aPoint;
    Distance := aDistance;
  end;
end;


procedure TNavMeshFloodFill.InsertInQueue(const aIdx: Word);
begin
  if IsQueueEmpty then
    fStartQueue := aIdx;
  fQueueArray[fEndQueue].Next := aIdx;
  fEndQueue := aIdx;
  fQueueCnt := fQueueCnt + 1;
end;


procedure TNavMeshFloodFill.InsertAndSort(const aIdx: Word);
var
  I, ActIdx, PrevIdx: Word;
begin
  if IsQueueEmpty then
  begin
    fStartQueue := aIdx;
    fEndQueue := fStartQueue;
  end
  else
  begin
    PrevIdx := fStartQueue;
    ActIdx := fStartQueue;
    I := 0;
    while (I < fQueueCnt) do // While must be here
    begin
      if (fQueueArray[aIdx].Distance < fQueueArray[ActIdx].Distance) then
        break;
      PrevIdx := ActIdx;
      ActIdx := fQueueArray[ActIdx].Next;
      I := I + 1;
    end;

    if (I = 0) then
    begin
      fQueueArray[aIdx].Next := fStartQueue;
      fStartQueue := aIdx;
    end
    else if (I = fQueueCnt) then
    begin
      fQueueArray[fEndQueue].Next := aIdx;
      fEndQueue := aIdx;
    end
    else
    begin
      fQueueArray[PrevIdx].Next := aIdx;
      fQueueArray[aIdx].Next := ActIdx;
    end;

    fQueueCnt := fQueueCnt + 1;
  end;
end;


function TNavMeshFloodFill.RemoveFromQueue(var aIdx: Word): Boolean;
begin
  Result := not IsQueueEmpty;
  if Result then
  begin
    aIdx := fStartQueue;
    fStartQueue := fQueueArray[fStartQueue].Next;
    fQueueCnt := fQueueCnt - 1;
  end;
end;


// Init Queue
procedure TNavMeshFloodFill.InitQueue(const aMaxIdx: Word; aInitIdxArray: TKMWordArray);
const
  INIT_DISTANCE = 0;
var
  I, Idx: Word;
  PolyArr: TPolygonArray;
begin
  PolyArr := gAIFields.NavMesh.Polygons;

  MakeNewQueue();
  for I := 0 to aMaxIdx do
  begin
    Idx := aInitIdxArray[I];
    if not IsVisited(Idx) then
    begin
      MarkAsVisited(Idx, INIT_DISTANCE, PolyArr[ Idx ].CenterPoint);
      InsertInQueue(Idx);
    end;
  end;
end;


procedure TNavMeshFloodFill.Flood();
var
  PolyArr: TPolygonArray;
  I, Idx, NearbyIdx: Word;
  Point: TKMPoint;
begin
  PolyArr := gAIFields.NavMesh.Polygons;

  while RemoveFromQueue(Idx) do
    if CanBeVisited(Idx) then
      for I := 0 to PolyArr[Idx].NearbyCount-1 do
      begin
        NearbyIdx := PolyArr[Idx].Nearby[I];
        if not IsVisited(NearbyIdx) then
        begin
          Point := PolyArr[Idx].NearbyPoints[I];
          MarkAsVisited( NearbyIdx,
                         fQueueArray[Idx].Distance + KMDistanceAbs(fQueueArray[Idx].DistPoint, Point),
                         Point);
          if fSorted then
            InsertAndSort(NearbyIdx)
          else
            InsertInQueue(NearbyIdx);
        end;
      end;
end;


function TNavMeshFloodFill.FillPolygons(const aMaxIdx: Word; aInitIdxArray: TKMWordArray): Boolean;
begin
  Result := (Length(aInitIdxArray) > 0);
  if Result then
  begin
    InitQueue(  Min( High(aInitIdxArray), aMaxIdx ), aInitIdxArray);
    Flood();
  end;
end;


end.


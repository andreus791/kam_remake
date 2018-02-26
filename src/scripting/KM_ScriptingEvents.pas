unit KM_ScriptingEvents;
{$I KaM_Remake.inc}
{$WARN IMPLICIT_STRING_CAST OFF}
interface
uses
  Classes, Math, SysUtils, StrUtils, uPSRuntime, uPSDebugger,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_Houses, KM_ScriptingIdCache, KM_Units,
  KM_UnitGroups, KM_ResHouses, KM_HouseCollection, KM_ResWares, KM_ScriptingTypes;


type
  TByteSet = set of Byte;

  TKMScriptEntity = class
  protected
    fIDCache: TKMScriptingIdCache;
    fOnScriptError: TKMScriptErrorEvent;
    procedure LogWarning(const aFuncName: string; aWarnMsg: String);
    procedure LogParamWarning(const aFuncName: string; const aValues: array of Integer);
  public
    constructor Create(aIDCache: TKMScriptingIdCache);
    property OnScriptError: TKMScriptErrorEvent write fOnScriptError;
  end;

  TKMCustomEventHandler = record
    Name: UnicodeString;
    Handler: TMethod;
  end;

  TKMScriptEvents = class(TKMScriptEntity)
  private
    fExec: TPSDebugExec;

    fEventHandlers: array[TKMScriptEventType] of array of TKMCustomEventHandler;

    procedure AddDefaultEventHandlersNames;
    procedure CallEventHandlers(aEventType: TKMScriptEventType; const aParams: array of Integer);

    procedure DoProc(const aProc: TMethod; const aParams: array of Integer);
    function MethodAssigned(aProc: TMethod): Boolean; overload; inline;
    function MethodAssigned(aEventType: TKMScriptEventType): Boolean; overload; inline;
  public
    ExceptionOutsideScript: Boolean; //Flag that the exception occured in a State or Action call not script

    constructor Create(aExec: TPSDebugExec; aIDCache: TKMScriptingIdCache);

    procedure AddEventHandlerName(aEventType: TKMScriptEventType; aEventHandlerName: UnicodeString);
    procedure LinkEvents;

    procedure ProcBeacon(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcFieldBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcHouseAfterDestroyed(aHouseType: TKMHouseType; aOwner: TKMHandIndex; aX, aY: Word);
    procedure ProcHouseBuilt(aHouse: TKMHouse);
    procedure ProcHousePlanDigged(aHouse: Integer);
    procedure ProcHousePlanPlaced(aPlayer: TKMHandIndex; aX, aY: Word; aType: TKMHouseType);
    procedure ProcHousePlanRemoved(aPlayer: TKMHandIndex; aX, aY: Word; aType: TKMHouseType);
    procedure ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
    procedure ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: TKMHandIndex);
    procedure ProcGroupHungry(aGroup: TKMUnitGroup);
    procedure ProcGroupOrderAttackHouse(aGroup: TKMUnitGroup; aHouse: TKMHouse);
    procedure ProcGroupOrderAttackUnit(aGroup: TKMUnitGroup; aUnit: TKMUnit);
    procedure ProcGroupOrderLink(aGroup1, aGroup2: TKMUnitGroup);
    procedure ProcGroupOrderSplit(aGroup, aNewGroup: TKMUnitGroup);
    procedure ProcMarketTrade(aMarket: TKMHouse; aFrom, aTo: TKMWareType);
    procedure ProcMissionStart;
    procedure ProcPlanRoadDigged(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanRoadPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanRoadRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanFieldPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanFieldRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanWinefieldDigged(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanWinefieldPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlanWinefieldRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcPlayerDefeated(aPlayer: TKMHandIndex);
    procedure ProcPlayerVictory(aPlayer: TKMHandIndex);
    procedure ProcRoadBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
    procedure ProcTick;
    procedure ProcUnitAfterDied(aUnitType: TKMUnitType; aOwner: TKMHandIndex; aX, aY: Word);
    procedure ProcUnitAttacked(aUnit, aAttacker: TKMUnit);
    procedure ProcUnitDied(aUnit: TKMUnit; aKillerOwner: TKMHandIndex);
    procedure ProcUnitTrained(aUnit: TKMUnit);
    procedure ProcUnitWounded(aUnit, aAttacker: TKMUnit);
    procedure ProcWareProduced(aHouse: TKMHouse; aType: TKMWareType; aCount: Word);
    procedure ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
    procedure ProcWarriorWalked(aUnit: TKMUnit; aToX, aToY: Integer);
    procedure ProcWinefieldBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
  end;


var
  gScriptEvents: TKMScriptEvents;


implementation
uses
  uPSUtils,
  TypInfo, KromUtils, KM_AI, KM_Terrain, KM_Game, KM_FogOfWar, KM_HandsCollection, KM_Units_Warrior,
  KM_HouseBarracks, KM_HouseSchool, KM_ResUnits, KM_Log, KM_CommonUtils, KM_HouseMarket,
  KM_Resource, KM_UnitTaskSelfTrain, KM_Sound, KM_Hand, KM_AIDefensePos, KM_CommonClasses,
  KM_UnitsCollection, KM_PathFindingRoad;


type
  TKMScriptEvent = procedure of object;
  TKMScriptEvent1I = procedure (aIndex: Integer) of object;
  TKMScriptEvent2I = procedure (aIndex, aParam: Integer) of object;
  TKMScriptEvent3I = procedure (aIndex, aParam1, aParam2: Integer) of object;
  TKMScriptEvent4I = procedure (aIndex, aParam1, aParam2, aParam3: Integer) of object;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


function HouseTypeValid(aHouseType: Integer): Boolean; inline;
begin
  Result := (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
            and (HouseIndexToType[aHouseType] <> ht_None); //KaM index 26 is unused (ht_None)
end;


{ TKMScriptEvents }
constructor TKMScriptEvents.Create(aExec: TPSDebugExec; aIDCache: TKMScriptingIdCache);
begin
  inherited Create(aIDCache);

  fExec := aExec;

  AddDefaultEventHandlersNames;
end;


procedure TKMScriptEvents.AddDefaultEventHandlersNames;
begin
  AddEventHandlerName(evtBeacon,                'OnBeacon');
  AddEventHandlerName(evtFieldBuilt,            'OnFieldBuilt');
  AddEventHandlerName(evtHouseAfterDestroyed,   'OnHouseAfterDestroyed');
  AddEventHandlerName(evtHouseBuilt,            'OnHouseBuilt');
  AddEventHandlerName(evtHousePlanDigged,       'OnHousePlanDigged');
  AddEventHandlerName(evtHousePlanPlaced,       'OnHousePlanPlaced');
  AddEventHandlerName(evtHousePlanRemoved,      'OnHousePlanRemoved');
  AddEventHandlerName(evtHouseDamaged,          'OnHouseDamaged');
  AddEventHandlerName(evtHouseDestroyed,        'OnHouseDestroyed');
  AddEventHandlerName(evtGroupHungry,           'OnGroupHungry');
  AddEventHandlerName(evtGroupOrderAttackHouse, 'OnGroupOrderAttackHouse');
  AddEventHandlerName(evtGroupOrderAttackUnit,  'OnGroupOrderAttackUnit');
  AddEventHandlerName(evtGroupOrderLink,        'OnGroupOrderLink');
  AddEventHandlerName(evtGroupOrderSplit,       'OnGroupOrderSplit');
  AddEventHandlerName(evtMarketTrade,           'OnMarketTrade');
  AddEventHandlerName(evtMissionStart,          'OnMissionStart');
  AddEventHandlerName(evtPlanRoadDigged,        'OnPlanRoadDigged');
  AddEventHandlerName(evtPlanRoadPlaced,        'OnPlanRoadPlaced');
  AddEventHandlerName(evtPlanRoadRemoved,       'OnPlanRoadRemoved');
  AddEventHandlerName(evtPlanFieldPlaced,       'OnPlanFieldPlaced');
  AddEventHandlerName(evtPlanFieldRemoved,      'OnPlanFieldRemoved');
  AddEventHandlerName(evtPlanWinefieldDigged,   'OnPlanWinefieldDigged');
  AddEventHandlerName(evtPlanWinefieldPlaced,   'OnPlanWinefieldPlaced');
  AddEventHandlerName(evtPlanWinefieldRemoved,  'OnPlanWinefieldRemoved');
  AddEventHandlerName(evtPlayerDefeated,        'OnPlayerDefeated');
  AddEventHandlerName(evtPlayerVictory,         'OnPlayerVictory');
  AddEventHandlerName(evtRoadBuilt,             'OnRoadBuilt');
  AddEventHandlerName(evtTick,                  'OnTick');
  AddEventHandlerName(evtUnitAfterDied,         'OnUnitAfterDied');
  AddEventHandlerName(evtUnitDied,              'OnUnitDied');
  AddEventHandlerName(evtUnitTrained,           'OnUnitTrained');
  AddEventHandlerName(evtUnitWounded,           'OnUnitWounded');
  AddEventHandlerName(evtUnitAttacked,          'OnUnitAttacked');
  AddEventHandlerName(evtWareProduced,          'OnWareProduced');
  AddEventHandlerName(evtWarriorEquipped,       'OnWarriorEquipped');
  AddEventHandlerName(evtWarriorWalked,         'OnWarriorWalked');
  AddEventHandlerName(evtWinefieldBuilt,        'OnWinefieldBuilt');
end;


procedure TKMScriptEvents.LinkEvents;
var
  I: Integer;
  ET: TKMScriptEventType;
begin
  for ET := Low(TKMScriptEventType) to High(TKMScriptEventType) do
    for I := Low(fEventHandlers[ET]) to High(fEventHandlers[ET]) do
    begin
      fEventHandlers[ET][I].Handler := fExec.GetProcAsMethodN(fEventHandlers[ET][I].Name);
      if (I > 0) //It's okay to not have default event handler
        and not MethodAssigned(fEventHandlers[ET][I].Handler) then
        fOnScriptError(se_PreprocessorError,
                       Format('Declared custom handler ''%s'' for event ''%s'' not found',
                              [fEventHandlers[ET][I].Name, GetEnumName(TypeInfo(TKMScriptEventType), Integer(ET))]));
    end;
end;


function TKMScriptEvents.MethodAssigned(aProc: TMethod): Boolean;
begin
  Result := aProc.Code <> nil;
end;


function TKMScriptEvents.MethodAssigned(aEventType: TKMScriptEventType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
  begin
    if fEventHandlers[aEventType][I].Handler.Code <> nil then
    begin
      Result := True;
      Exit;
    end;
  end;
end;


procedure TKMScriptEvents.AddEventHandlerName(aEventType: TKMScriptEventType; aEventHandlerName: UnicodeString);
var
  I, Len: Integer;
begin
  Assert(Trim(aEventHandlerName) <> '', 'Can''t add empty event handler for event type: ' +
         GetEnumName(TypeInfo(TKMScriptEventType), Integer(aEventType)));
  for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
    if UpperCase(fEventHandlers[aEventType][I].Name) = UpperCase(aEventHandlerName) then
      fOnScriptError(se_PreprocessorError,
                     Format('Duplicate event handler declaration ''%s'' for event ''%s''',
                     [aEventHandlerName, GetEnumName(TypeInfo(TKMScriptEventType), Integer(aEventType))]));

  Len := Length(fEventHandlers[aEventType]);
  SetLength(fEventHandlers[aEventType], Len + 1);
  fEventHandlers[aEventType][Len].Name := aEventHandlerName;
end;



procedure TKMScriptEvents.CallEventHandlers(aEventType: TKMScriptEventType; const aParams: array of Integer);
var
  I: Integer;
begin
  for I := Low(fEventHandlers[aEventType]) to High(fEventHandlers[aEventType]) do
    DoProc(fEventHandlers[aEventType][I].Handler, aParams);
end;


//This procedure allows us to keep the exception handling code in one place
procedure TKMScriptEvents.DoProc(const aProc: TMethod; const aParams: array of Integer);
var
  ExceptionProc: TPSProcRec;
  InternalProc: TPSInternalProcRec;
  MainErrorStr, ErrorStr, DetailedErrorStr: UnicodeString;
  Pos, Row, Col: Cardinal;
  TBTFileName: tbtstring;
  ErrorMessage: TKMScriptErrorMessage;
begin
  if not MethodAssigned(aProc) then Exit;

  try
    case Length(aParams) of
      0: TKMScriptEvent(aProc);
      1: TKMScriptEvent1I(aProc)(aParams[0]);
      2: TKMScriptEvent2I(aProc)(aParams[0], aParams[1]);
      3: TKMScriptEvent3I(aProc)(aParams[0], aParams[1], aParams[2]);
      4: TKMScriptEvent4I(aProc)(aParams[0], aParams[1], aParams[2], aParams[3]);
      else raise Exception.Create('Unexpected Length(aParams)');
    end;
  except
    on E: Exception do
      if ExceptionOutsideScript then
      begin
        ExceptionOutsideScript := False; //Reset
        raise; //Exception was in game code not script, so pass up to madExcept
      end
      else
      begin
        DetailedErrorStr := '';
        MainErrorStr := 'Exception in script: ''' + E.Message + '''';
        ExceptionProc := fExec.GetProcNo(fExec.ExceptionProcNo);
        if ExceptionProc is TPSInternalProcRec then
        begin
          InternalProc := TPSInternalProcRec(ExceptionProc);
          MainErrorStr := MainErrorStr + EolW + 'in procedure ''' + UnicodeString(InternalProc.ExportName) + '''' + EolW;
          // With the help of uPSDebugger get information about error position in script code
          if fExec.TranslatePositionEx(fExec.LastExProc, fExec.LastExPos, Pos, Row, Col, TBTFileName) then
          begin
            ErrorMessage := gGame.Scripting.GetErrorMessage('Error', '', Row, Col);
            ErrorStr := MainErrorStr + ErrorMessage.GameMessage;
            DetailedErrorStr := MainErrorStr + ErrorMessage.LogMessage;
          end;
        end;
        fOnScriptError(se_Exception, ErrorStr, DetailedErrorStr);
      end;
  end;
end;


//* Version: 6570
//* Occurs when a player places a beacon on the map.
procedure TKMScriptEvents.ProcBeacon(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtBeacon) then
    CallEventHandlers(evtBeacon, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when player built a field.
procedure TKMScriptEvents.ProcFieldBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtFieldBuilt) then
    CallEventHandlers(evtFieldBuilt, [aPlayer, aX, aY]);
end;


//* Version: 6216
//* Occurs when a trade happens in a market (at the moment when resources are exchanged by serfs).
procedure TKMScriptEvents.ProcMarketTrade(aMarket: TKMHouse; aFrom, aTo: TKMWareType);
begin
  if MethodAssigned(evtMarketTrade) then
  begin
    fIDCache.CacheHouse(aMarket, aMarket.UID); //Improves cache efficiency since aMarket will probably be accessed soon
    CallEventHandlers(evtMarketTrade, [aMarket.UID, WareTypeToIndex[aFrom], WareTypeToIndex[aTo]]);
  end;
end;


//* Version: 5057
//* Occurs immediately after the mission is loaded.
procedure TKMScriptEvents.ProcMissionStart;
begin
  if MethodAssigned(evtMissionStart) then
    CallEventHandlers(evtMissionStart, []);
end;


//* Version: 5057
//* Occurs every game logic update.
procedure TKMScriptEvents.ProcTick;
begin
  if MethodAssigned(evtTick) then
    CallEventHandlers(evtTick, []);
end;


//* Version: 5057
//* Occurs when player has built a house.
procedure TKMScriptEvents.ProcHouseBuilt(aHouse: TKMHouse);
begin
  if MethodAssigned(evtHouseBuilt) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseBuilt, [aHouse.UID]);
  end;
end;


//* Version: 5882
//* Occurs when a house is damaged by the enemy soldier.
//* Attacker is -1 the house was damaged some other way, such as from Actions.HouseAddDamage.
procedure TKMScriptEvents.ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
begin
  if MethodAssigned(evtHouseDamaged) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtHouseDamaged, [aHouse.UID, aAttacker.UID]);
    end
    else
      //House was damaged, but we don't know by whom (e.g. by script command)
      CallEventHandlers(evtHouseDamaged, [aHouse.UID, PLAYER_NONE]);
  end;
end;


//* Version: 5407
//* Occurs when a house is destroyed.
//* If DestroyerIndex is -1 the house was destroyed some other way, such as from Actions.HouseDestroy.
//* If DestroyerIndex is the same as the house owner (States.HouseOwner), the house was demolished by the player who owns it.
//* Otherwise it was destroyed by an enemy.
//* Called just before the house is destroyed so HouseID is usable only during this event, and the area occupied by the house is still unusable.
//* aDestroyerIndex: Index of player who destroyed it
procedure TKMScriptEvents.ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: TKMHandIndex);
begin
  if MethodAssigned(evtHouseDestroyed) then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtHouseDestroyed, [aHouse.UID, aDestroyerIndex]);
  end;
end;


//* Version: 6114
//* Occurs after a house is destroyed and has been completely removed from the game,
//* meaning the area it previously occupied can be used.
//* If you need more information about the house use the OnHouseDestroyed event.
procedure TKMScriptEvents.ProcHouseAfterDestroyed(aHouseType: TKMHouseType; aOwner: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtHouseAfterDestroyed) then
    CallEventHandlers(evtHouseAfterDestroyed, [HouseTypeToIndex[aHouseType] - 1, aOwner, aX, aY]);
end;


//* Version: 7000+
//* Occurs when house plan is digged.
procedure TKMScriptEvents.ProcHousePlanDigged(aHouse: Integer);
begin
  if MethodAssigned(evtHousePlanDigged) then
    CallEventHandlers(evtHousePlanDigged, [aHouse]);
end;


//* Version: 5871
//* Occurs when player has placed a house plan.
procedure TKMScriptEvents.ProcHousePlanPlaced(aPlayer: TKMHandIndex; aX, aY: Word; aType: TKMHouseType);
begin
  if MethodAssigned(evtHousePlanPlaced) then
    CallEventHandlers(evtHousePlanPlaced, [aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, HouseTypeToIndex[aType] - 1]);
end;


//* Version: 6298
//* Occurs when player has removed a house plan.
procedure TKMScriptEvents.ProcHousePlanRemoved(aPlayer: TKMHandIndex; aX, aY: Word; aType: TKMHouseType);
begin
  if MethodAssigned(evtHousePlanRemoved) then
    CallEventHandlers(evtHousePlanRemoved, [aPlayer, aX + gRes.Houses[aType].EntranceOffsetX, aY, HouseTypeToIndex[aType] - 1]);
end;


//* Version: 6220
//* Occurs when the player would be shown a message about a group being hungry
//* (when they first get hungry, then every 4 minutes after that if there are still hungry group members).
//* Occurs regardless of whether the group has hunger messages enabled or not.
procedure TKMScriptEvents.ProcGroupHungry(aGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupHungry) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    CallEventHandlers(evtGroupHungry, [aGroup.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to attack house
//* aGroup: attackers group ID
//* aHouse: target house ID
procedure TKMScriptEvents.ProcGroupOrderAttackHouse(aGroup: TKMUnitGroup; aHouse: TKMHouse);
begin
  if MethodAssigned(evtGroupOrderAttackHouse) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    CallEventHandlers(evtGroupOrderAttackHouse, [aGroup.UID, aHouse.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to attack unit
//* aGroup: attackers group ID
//* aUnit: target unit ID
procedure TKMScriptEvents.ProcGroupOrderAttackUnit(aGroup: TKMUnitGroup; aUnit: TKMUnit);
begin
  if MethodAssigned(evtGroupOrderAttackUnit) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID); //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheUnit(aUnit, aUnit.UID);    //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtGroupOrderAttackUnit, [aGroup.UID, aUnit.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group1 gets order to link to group2
//* aGroup1: link group ID
//* aGroup2: link target group ID
procedure TKMScriptEvents.ProcGroupOrderLink(aGroup1, aGroup2: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupOrderLink) then
  begin
    fIDCache.CacheGroup(aGroup1, aGroup1.UID); //Improves cache efficiency since aGroup1 will probably be accessed soon
    fIDCache.CacheGroup(aGroup2, aGroup2.UID); //Improves cache efficiency since aGroup2 will probably be accessed soon
    CallEventHandlers(evtGroupOrderLink, [aGroup1.UID, aGroup2.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when the group gets order to split
//* aGroup: group ID
//* aNewGroup: splitted group ID
procedure TKMScriptEvents.ProcGroupOrderSplit(aGroup, aNewGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtGroupOrderLink) then
  begin
    fIDCache.CacheGroup(aGroup, aGroup.UID);       //Improves cache efficiency since aGroup will probably be accessed soon
    fIDCache.CacheGroup(aNewGroup, aNewGroup.UID); //Improves cache efficiency since aNewGroup will probably be accessed soon
    CallEventHandlers(evtGroupOrderSplit, [aGroup.UID, aNewGroup.UID]);
  end;
end;


//* Version: 5407
//* Occurs when a unit dies. If KillerIndex is -1 the unit died from another cause such as hunger or Actions.UnitKill.
//* Called just before the unit is killed so UnitID is usable only during this event,
//* and the tile occupied by the unit is still taken.
//* aKillerOwner: Index of player who killed it
procedure TKMScriptEvents.ProcUnitDied(aUnit: TKMUnit; aKillerOwner: TKMHandIndex);
begin
  if MethodAssigned(evtUnitDied) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtUnitDied, [aUnit.UID, aKillerOwner]);
  end;
end;


//* Version: 6114
//* Occurs after a unit has died and has been completely removed from the game, meaning the tile it previously occupied can be used.
//* If you need more information about the unit use the OnUnitDied event.
//* Note: Because units have a death animation there is a delay of several ticks between OnUnitDied and OnUnitAfterDied.
procedure TKMScriptEvents.ProcUnitAfterDied(aUnitType: TKMUnitType; aOwner: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtUnitAfterDied) then
    CallEventHandlers(evtUnitAfterDied, [UnitTypeToIndex[aUnitType], aOwner, aX, aY]);
end;


//* Version: 6587
//* Happens when a unit is attacked (shot at by archers or hit in melee).
//* Attacker is always a warrior (could be archer or melee).
//* This event will occur very frequently during battles.
//* aAttacker: Warrior who attacked the unit
procedure TKMScriptEvents.ProcUnitAttacked(aUnit, aAttacker: TKMUnit);
begin
  if MethodAssigned(evtUnitAttacked) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtUnitAttacked, [aUnit.UID, aAttacker.UID]);
    end
    else
      CallEventHandlers(evtUnitAttacked, [aUnit.UID, -1]);
  end;
end;


//* Version: 5057
//* Occurs when player trains a unit.
procedure TKMScriptEvents.ProcUnitTrained(aUnit: TKMUnit);
begin
  if MethodAssigned(evtUnitTrained) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    CallEventHandlers(evtUnitTrained, [aUnit.UID]);
  end;
end;


//* Version: 5884
//* Happens when unit is wounded.
//* Attacker can be a warrior, recruit in tower or unknown (-1).
//* aAttacker: Unit who attacked the unit
procedure TKMScriptEvents.ProcUnitWounded(aUnit, aAttacker: TKMUnit);
begin
  if MethodAssigned(evtUnitWounded) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      CallEventHandlers(evtUnitWounded, [aUnit.UID, aAttacker.UID]);
    end
    else
      CallEventHandlers(evtUnitWounded, [aUnit.UID, PLAYER_NONE]);
  end;
end;


//* Version: 5057
//* Occurs when player equips a warrior.
procedure TKMScriptEvents.ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
begin
  if MethodAssigned(evtWarriorEquipped) then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    fIDCache.CacheGroup(aGroup, aGroup.UID);
    CallEventHandlers(evtWarriorEquipped, [aUnit.UID, aGroup.UID]);
  end;
end;


//* Version: 7000+
//* Occurs when road plan is digged.
procedure TKMScriptEvents.ProcPlanRoadDigged(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanRoadDigged) then
    CallEventHandlers(evtPlanRoadDigged, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a road plan.
procedure TKMScriptEvents.ProcPlanRoadPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanRoadPlaced) then
    CallEventHandlers(evtPlanRoadPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a road plan.
procedure TKMScriptEvents.ProcPlanRoadRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanRoadRemoved) then
    CallEventHandlers(evtPlanRoadRemoved, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a field plan.
procedure TKMScriptEvents.ProcPlanFieldPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanFieldPlaced) then
    CallEventHandlers(evtPlanFieldPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a field plan.
procedure TKMScriptEvents.ProcPlanFieldRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanFieldRemoved) then
    CallEventHandlers(evtPlanFieldRemoved, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when winefield is digged
procedure TKMScriptEvents.ProcPlanWinefieldDigged(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanWinefieldDigged) then
    CallEventHandlers(evtPlanWinefieldDigged, [aPlayer, aX, aY]);
end;


//* Version: 5964
//* Occurs when player has placed a wine field plan.
procedure TKMScriptEvents.ProcPlanWinefieldPlaced(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanWinefieldPlaced) then
    CallEventHandlers(evtPlanWinefieldPlaced, [aPlayer, aX, aY]);
end;


//* Version: 6301
//* Occurs when player has removed a wine field plan.
procedure TKMScriptEvents.ProcPlanWinefieldRemoved(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtPlanWinefieldRemoved) then
    CallEventHandlers(evtPlanWinefieldRemoved, [aPlayer, aX, aY]);
end;


//* Version: 5057
//* Occurs when certain player has been defeated.
//* Defeat conditions are checked separately by Player AI.
procedure TKMScriptEvents.ProcPlayerDefeated(aPlayer: TKMHandIndex);
begin
  if MethodAssigned(evtPlayerDefeated) then
    CallEventHandlers(evtPlayerDefeated, [aPlayer]);
end;


//* Version: 5057
//* Occurs when certain player is declared victorious.
//* Victory conditions are checked separately by Player AI.
procedure TKMScriptEvents.ProcPlayerVictory(aPlayer: TKMHandIndex);
begin
  if MethodAssigned(evtPlayerVictory) then
    CallEventHandlers(evtPlayerVictory, [aPlayer]);
end;


//* Version: 7000+
//* Occurs when player built a road.
procedure TKMScriptEvents.ProcRoadBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtRoadBuilt) then
    CallEventHandlers(evtRoadBuilt, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when player built a winefield.
procedure TKMScriptEvents.ProcWinefieldBuilt(aPlayer: TKMHandIndex; aX, aY: Word);
begin
  if MethodAssigned(evtWinefieldBuilt) then
    CallEventHandlers(evtWinefieldBuilt, [aPlayer, aX, aY]);
end;


//* Version: 7000+
//* Occurs when resource is produced for specified house.
procedure TKMScriptEvents.ProcWareProduced(aHouse: TKMHouse; aType: TKMWareType; aCount: Word);
begin
  if MethodAssigned(evtWareProduced) then
  begin
    if (aType <> wt_None) then
      CallEventHandlers(evtWareProduced, [aHouse.UID, WareTypeToIndex[aType], aCount]);
  end;
end;


//* Version: 7000+
//* Occurs when warrior walk
procedure TKMScriptEvents.ProcWarriorWalked(aUnit: TKMUnit; aToX, aToY: Integer);
begin
  if MethodAssigned(evtWarriorWalked) then
      CallEventHandlers(evtWarriorWalked, [aUnit.UID, aToX, aToY]);
end;


{ TKMScriptEntity }
constructor TKMScriptEntity.Create(aIDCache: TKMScriptingIdCache);
begin
  inherited Create;
  fIDCache := aIDCache;
end;


procedure TKMScriptEntity.LogWarning(const aFuncName: string; aWarnMsg: String);
begin
  fOnScriptError(se_Log, 'Warning in ' + aFuncName + ': ' + aWarnMsg);
end;


procedure TKMScriptEntity.LogParamWarning(const aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  Values := '';
  for I := Low(aValues) to High(aValues) do
    Values := Values + String(IntToStr(aValues[I])) + IfThen(I <> High(aValues), ', ');
  fOnScriptError(se_InvalidParameter, 'Invalid parameter(s) passed to ' + aFuncName + ': ' + Values);
end;


end.

unit KM_ScriptingTypes;
{$I KaM_Remake.inc}
interface

type
  TKMScriptEventType = (
    evtBeacon,
    evtFieldBuilt,
    evtHouseAfterDestroyed,
    evtHouseBuilt,
    evtHousePlanDigged,
    evtHousePlanPlaced,
    evtHousePlanRemoved,
    evtHouseDamaged,
    evtHouseDestroyed,
    evtHouseWareCountChanged,
    evtGameSpeedChanged,
    evtGroupHungry,
    evtGroupOrderAttackHouse,
    evtGroupOrderAttackUnit,
    evtGroupBeforeOrderSplit,
    evtGroupOrderMove,
    evtGroupOrderLink,
    evtGroupOrderSplit,
    evtMarketTrade,
    evtMissionStart,
    evtPeacetimeEnd,
    evtPlanRoadDigged,
    evtPlanRoadPlaced,
    evtPlanRoadRemoved,
    evtPlanFieldPlaced,
    evtPlanFieldRemoved,
    evtPlanWinefieldDigged,
    evtPlanWinefieldPlaced,
    evtPlanWinefieldRemoved,
    evtPlayerDefeated,
    evtPlayerVictory,
    evtRoadBuilt,
    evtTick,
    evtUnitAfterDied,
    evtUnitDied,
    evtUnitTrained,
    evtUnitWounded,
    evtUnitAttacked,
    evtWareProduced,
    evtWarriorEquipped,
    evtWarriorWalked,
    evtWinefieldBuilt
  );


  TKMScriptFileInfo = record
    FullFilePath: UnicodeString;
    FileName: UnicodeString;
    FileText: AnsiString;
  end;

  // Script error message
  TKMScriptErrorMessage = record
    GameMessage: UnicodeString; // Shown in game as Message box
    LogMessage: UnicodeString;  // Printed to Log (could be more detailed)
  end;

  TKMScriptErrorType = (seInvalidParameter, seException, sePreprocessorError, seCompileError, seCompileWarning, seCompileHint, seLog);

  TKMScriptErrorEvent = procedure (aType: TKMScriptErrorType; const aErrorString: UnicodeString; const aDetailedErrorString: UnicodeString = '') of object;


implementation

end.


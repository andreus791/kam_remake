unit KM_Defaults;
{$I KaM_Remake.inc}
interface
uses
  SysUtils;

//Global constants
const
//|===================| <- constant name length
  MAX_MAP_SIZE          = 256;
  MIN_MAP_SIZE          = 32;
  CELL_SIZE_PX          = 40;           //Single cell size in pixels (width)
  CELL_HEIGHT_DIV       = 33.333;       //Height divider, controlls terrains pseudo-3d look
  TOOLBAR_WIDTH         = 224;          //Toolbar width in game
  TERRAIN_PACE          = 200;          //Each tile gets updated once per ** ticks (100 by default), Warning, it affects field/tree growth rate
  FOW_PACE              = 10;           //Each tile gets updated once per ** ticks (10 by default)

  MIN_FPS_CAP           = 10;           //Minimum FPS Cap - limit fps
  DEF_FPS_CAP           = 60;           //Default FPS Cap
  MAX_FPS_CAP           = 1000;         //Maximum FPS Cap (means no CAP at all)
  FPS_INTERVAL          = 1000;         //Time in ms between FPS measurements, bigger value = more accurate result
  MENU_DESIGN_X         = 1024;         //Thats the size menu was designed for. All elements are placed in this size
  MENU_DESIGN_Y         = 768;          //Thats the size menu was designed for. All elements are placed in this size
  MIN_RESOLUTION_WIDTH  = 1024;         //Lowest supported resolution X
  MIN_RESOLUTION_HEIGHT = 576;          //Lowest supported resolution Y
  {$I KM_Revision.inc};
  {$IFDEF USESECUREAUTH}
    GAME_VERSION_POSTFIX  = '';
  {$ELSE}
    GAME_VERSION_POSTFIX  = ' (UNSECURE!)';
  {$ENDIF}
  GAME_VERSION_PREFIX   = ''; //Game version string displayed in menu corner
var
  //Game revision is set in initialisation block
  GAME_REVISION: AnsiString; //Should be updated for every release (each time save format is changed)
  GAME_VERSION: AnsiString;
  NET_PROTOCOL_REVISON: AnsiString; //Clients of this version may connect to the dedicated server
const
  SETTINGS_FILE         = 'KaM_Remake_Settings.ini';
  FONTS_FOLDER          = 'data' + PathDelim + 'gfx' + PathDelim + 'fonts' + PathDelim;
  DEFAULT_LOCALE: AnsiString = 'eng';

  DEL_LOGS_OLDER_THAN   = 14;           //in days

  TEMPLATE_LIBX_FILE_TEXT = 'text.%s.libx';
const
  //Max number of ticks, played on 1 game update.
  //We must limit number of ticks per update to be able to leave update cycle fast (when turn off ultra fast speedup, f.e.)
  //Also there is a technical limit, of how many ticks we can calculate per update
  MAX_TICKS_PER_GAME_UPDATE = 100;

var
  // These should be True (we can occasionally turn them Off to speed up the debug)
  CALC_EXPECTED_TICK    :Boolean = True;  //Do we calculate expected tick and try to be in-time (send as many tick as needed to get to expected tick)
  MAKE_ANIM_TERRAIN     :Boolean = True;  //Should we animate water and swamps
  MAKE_TEAM_COLORS      :Boolean = True;  //Whenever to make team colors or not, saves RAM for debug
  DYNAMIC_TERRAIN       :Boolean = True;  //Update terrain each tick to grow things
  KAM_WATER_DRAW        :Boolean = True;  //Render underwater sand
  CHEATS_SP_ENABLED     :Boolean = True;  //Enable cheats in game (add_resource, instant_win, etc)
  FREE_POINTERS         :Boolean = True;  //If True, units/houses will be freed and removed from the list once they are no longer needed
  CAP_MAX_FPS           :Boolean = True;  //Should limit rendering performance to avoid GPU overheating (disable to measure debug performance)
  CRASH_ON_REPLAY       :Boolean = True;  //Crash as soon as replay consistency fails (random numbers mismatch)
  BLOCK_DUPLICATE_APP   :Boolean = True;  //Do not allow to run multiple games at once (to prevent MP cheating)
  SHOW_DISMISS_UNITS_BTN:Boolean = True; //The button to order citizens go back to school

  //Implemented
  DO_UNIT_INTERACTION   :Boolean = True; //Debug for unit interaction
  DO_WEIGHT_ROUTES      :Boolean = True; //Add additional cost to tiles in A* if they are occupied by other units (IsUnit=1)
  CUSTOM_RANDOM         :Boolean = True; //Use our custom random number generator or the built in "Random()"
  USE_WALKING_DISTANCE  :Boolean = True; //Use the walking distance for deciding place to mine rather than direct distance
  RANDOM_TARGETS        :Boolean = True; //Archers use random targets instead of closest
  DISPLAY_CHARTS_RESULT :Boolean = True; //Show charts in game results screen
  HUNGARIAN_GROUP_ORDER :Boolean = True; //Use Hungarian algorithm to reorder warrior groups when walking
  AI_GEN_NAVMESH        :Boolean = True; //Generate navmesh for AI to plan attacks/defenses
  AI_GEN_INFLUENCE_MAPS :Boolean = True; //Generate influence maps for AI to plan attacks/defenses
  //Not fully implemented yet
  USE_CCL_WALKCONNECT   :Boolean = False; //Use CCL instead of FloodFill for walk-connect (CCL is generaly worse. It's a bit slower, counts 1 tile areas and needs more AreaIDs to work / makes sparsed IDs)
  DYNAMIC_FOG_OF_WAR    :Boolean = False; //Whenever dynamic fog of war is enabled or not
  SHOW_DISMISS_GROUP_BTN:Boolean = False; //The button to kill group
  CACHE_PATHFINDING     :Boolean = False; //Cache routes incase they are needed soon (Vortamic PF runs x4 faster even with lame approach)
  SNOW_HOUSES           :Boolean = False; //Draw snow on houses
  CHECK_8087CW          :Boolean = False; //Check that 8087CW (FPU flags) are set correctly each frame, in case some lib/API changed them
  SCROLL_ACCEL          :Boolean = False; //Acceleration for viewport scrolling
  PathFinderToUse       :Byte = 1;

  DELIVERY_BID_CALC_USE_PATHFINDING :Boolean = True; //Do we use simple distance on map or pathfinding for calc delivery bids cost?
  {$IFDEF WDC} //Work only in Delphi
  CACHE_DELIVERY_BIDS   :Boolean = True; //Cache delivery bids cost. Must be turned ON if we want to use pathfinding for bid calc, huge impact on performance in that case
  {$ENDIF}

  WARFARE_ORDER_SEQUENTIAL    :Boolean = True; //Pick weapon orders like KaM did
  WARFARE_ORDER_PROPORTIONAL  :Boolean = False; //New proportional way (looks like a bad idea)

  //These are debug things, should be False
  {AI}
  SP_DEFAULT_ADVANCED_AI  :Boolean = False; //Set advanced AI as default for SP games
  SP_DEFAULT_PEACETIME    :Integer = 70;    //Default peacetime for SP games when SP_DEFAULT_ADVANCED_AI set to True
  {User interface options}
  DEBUG_SPEEDUP_SPEED     :Integer = 300;   //Speed for speedup from debug menu
  DEBUG_LOGS              :Boolean = True;  //Log debug info
  ALLOW_SELECT_ALLY_UNITS :Boolean = False; //Do we allow to select ally units or groups
  ALLOW_SELECT_ENEMIES    :Boolean = False; //Do we allow to select enemies houses/units/groups
  SHOW_ENEMIES_STATS      :Boolean = False; //Do we allow to show enemies stats during the game
  SHOW_DEBUG_CONTROLS     :Boolean = False; //Show debug panel / Form1 menu (F11)
  SHOW_CONTROLS_OVERLAY   :Boolean = False; //Draw colored overlays ontop of controls! always Off here
  SHOW_CONTROLS_ID        :Boolean = False; //Draw controls ID
  SHOW_CONTROLS_FOCUS     :Boolean = False; //Outline focused control
  SHOW_TEXT_OUTLINES      :Boolean = False; //Display text areas outlines
  ENABLE_DESIGN_CONTORLS  :Boolean = False; //Enable special mode to allow to move/edit controls
  MODE_DESIGN_CONTORLS    :Boolean = False; //Special mode to move/edit controls activated by F7, it must block OnClick events! always Off here
  OVERLAY_RESOLUTIONS     :Boolean = False; //Render constraining frame
  LOCAL_SERVER_LIST       :Boolean = False; //Instead of loading server list from master server, add localhost:56789 (good for testing)
  SHOW_LOGS_IN_CHAT       :Boolean = False; //Show log messages in MP game chat
  LOG_GAME_TICK           :Boolean = False; //Log game tick
  {Gameplay display}
  SKIP_RENDER             :Boolean = False; //Skip all the rendering in favor of faster logic
  SKIP_SOUND              :Boolean = False; //Skip all the sounds in favor of faster logic
  SKIP_LOADING_CURSOR     :Boolean = False; //Skip loading and setting cursor
  AGGRESSIVE_REPLAYS      :Boolean = False; //Write a command gic_TempDoNothing every tick in order to find exactly when a replay mismatch occurs
  SHOW_GAME_TICK          :Boolean = False; //Show game tick next to game time
  SHOW_TERRAIN_IDS        :Boolean = False; //Show number of every tile terrain on it (also show layers terrain ids)
  SHOW_TERRAIN_KINDS      :Boolean = False; //Show terrain kind ids on every tile corner
  SHOW_TERRAIN_TILES_GRID :Boolean = False; //Show terrain tiles grid
  SHOW_BRUSH_APPLY_AREA   :Boolean = False; //Show brushes apply area
  SHOW_TERRAIN_WIRES      :Boolean = False; //Makes terrain height visible
  SHOW_TERRAIN_PASS       :Byte = 0; //Byte(TKMTerrainPassability)
  SHOW_UNIT_ROUTES        :Boolean = False; //Draw unit routes
  SHOW_SEL_BUFFER         :Boolean = False; //Display selection buffer
  SHOW_PROJECTILES        :Boolean = False; //Shows projectiles trajectory
  SHOW_POINTER_DOTS       :Boolean = False; //Show pointer count as small dots below unit/houses
  SHOW_GROUND_LINES       :Boolean = False; //Show a line below all sprites to mark the ground height used in Z-Order
  SHOW_UNIT_MOVEMENT      :Boolean = False; //Draw unit movement overlay (occupied tile), Only if unit interaction enabled
  SHOW_WALK_CONNECT       :Boolean = False; //Show floodfill areas of interconnected areas
  SHOW_DEFENCE_POSITIONS  :Boolean = False;
  TEST_VIEW_CLIP_INSET    :Boolean = False; //Renders smaller area to see if everything gets clipped well
  OUTLINE_ALL_SPRITES     :Boolean = False; //Render outline around every sprite
  SHOW_ATTACK_RADIUS      :Boolean = False; //Render towers/archers attack radius
  DISPLAY_SOUNDS          :Boolean = False; //Display sounds on map
  RENDER_3D               :Boolean = False; //Experimental 3D render
  HOUSE_BUILDING_STEP     :Single = 0;
  OVERLAY_NAVMESH         :Boolean = False; //Show navmesh
  OVERLAY_DEFENCES        :Boolean = False; //Show AI defence perimeters
  OVERLAY_INFLUENCE       :Boolean = False; //Show influence map
  OVERLAY_OWNERSHIP       :Boolean = False; //Show ownership map
  OVERLAY_AVOID           :Boolean = False; //Show avoidance map
  OVERLAY_AI_BUILD        :Boolean = False; //Show build progress of new AI
  OVERLAY_AI_COMBAT       :Boolean = False; //Show combat marks of new AI
  OVERLAY_AI_EYE          :Boolean = False; //Show Eye vision of new AI
  OVERLAY_AI_SUPERVISOR   :Boolean = False; //Show Supervisor vision of new AI 
  {Stats}
  SHOW_SPRITE_COUNT     :Boolean = False; //display rendered controls/sprites count
  SHOW_POINTER_COUNT    :Boolean = False; //Show debug total count of unit/house pointers being tracked
  SHOW_CMDQUEUE_COUNT   :Boolean = False; //Show how many commands were processed and stored by TGameInputProcess
  SHOW_NETWORK_DELAY    :Boolean = False; //Show the current delay in multiplayer game
  SHOW_ARMYEVALS        :Boolean = False; //Show result of enemy armies evaluation
  SHOW_AI_WARE_BALANCE  :Boolean = False; //Show wares balance (Produced - Consumed)
  SHOW_OVERLAY_BEVEL    :Boolean = False; //Show wares balance overlay Bevel (for better text readability)
  SHOW_NET_PACKETS_STATS:Boolean = False; //Show network packet statistics
  SHOW_NET_PACKETS_LIMIT:Integer = 1;
  INI_HITPOINT_RESTORE  :Boolean = False; //Use the hitpoint restore rate from the INI file to compare with KaM
  SLOW_MAP_SCAN         :Boolean = False; //Scan maps with a pause to emulate uncached file access
  SLOW_SAVE_SCAN        :Boolean = False; //Scan saves with a pause to emulate uncached file access
  DO_PERF_LOGGING       :Boolean = False; //Write each ticks time to log
  MP_RESULTS_IN_SP      :Boolean = False; //Display each players stats in SP
  {Gameplay}
  USE_CUSTOM_SEED       :Boolean = False; //Use custom seed for every game
  CUSTOM_SEED_VALUE     :Integer = 0;     //Custom seed value
  PAUSE_GAME_AT_TICK    :Integer = -1;    //Pause at specified game tick
  {Gameplay cheats}
  UNLOCK_CAMPAIGN_MAPS  :Boolean = False; //Unlock more maps for debug
  REDUCE_SHOOTING_RANGE :Boolean = False; //Reduce shooting range for debug
  MULTIPLAYER_CHEATS    :Boolean = False; //Allow cheats and debug overlays (e.g. CanWalk) in Multiplayer
  DEBUG_CHEATS          :Boolean = False; //Cheats for debug (place scout and reveal map) which can be turned On from menu
  MULTIPLAYER_SPEEDUP   :Boolean = False; //Allow you to use F8 to speed up multiplayer for debugging (only effects local client)
  SKIP_EXE_CRC          :Boolean = False; //Don't check KaM_Remake.exe CRC before MP game (useful for testing with different versions)
  ALLOW_MP_MODS         :Boolean = False; //Don't let people enter MP mode if they are using mods (unit.dat, house.dat, etc.)
  ALLOW_TAKE_AI_PLAYERS :Boolean = False; //Allow to load SP maps without Human player (usefull for AI testing)
  {Data output}
  BLOCK_SAVE            :Boolean = False; //Block saving game (used in parallel Runner)
  BLOCK_FILE_WRITE      :Boolean = False; //Block to write into txt file (used in parallel Runner)
  WRITE_DECODED_MISSION :Boolean = False; //Save decoded mission as txt file
  WRITE_WALKTO_LOG      :Boolean = False; //Write even more output into log + slows down game noticably
  WriteResourceInfoToTXT:Boolean = False; //Whenever to write txt files with defines data properties on loading
  EXPORT_SPRITE_ATLASES :Boolean = False; //Whenever to write all generated textures to BMP on loading (extremely time consuming)
  EXPORT_INFLUENCE      :Boolean = False;
  {Statistic}
  CtrlPaintCount: Word; //How many Controls were painted in last frame


const
  MAX_WARES_IN_HOUSE     = 5;    //Maximum resource items allowed to be in house
  MAX_WARES_OUT_WORKSHOP = 5;    //Maximum sum resource items allowed to output in workshops. Value: 5 - 20;
  MAX_WARES_ORDER        = 999;  //Number of max allowed items to be ordered in production houses (Weapon/Armor/etc)

  MAX_UNITS_AROUND_HOUSE = 50;

const
  MAX_WOODCUTTER_CUT_PNT_DISTANCE = 5; //Max distance for woodcutter new cutting point from his house

const
  MAX_HANDS            = 12; //Maximum players (human or AI) per map
  MAX_LOBBY_PLAYERS    = 12;  //Maximum number of players (not spectators) allowed in the lobby. Map can have additional AI locations up to MAX_HANDS (for co-op).
  MAX_LOBBY_SPECTATORS = 2;  //Slots available in lobby. Additional slots can be used by spectators
  MAX_LOBBY_SLOTS      = MAX_LOBBY_PLAYERS + MAX_LOBBY_SPECTATORS;
  MAX_TEAMS            = MAX_LOBBY_PLAYERS div 2;

  AUTOSAVE_COUNT          = 5;    //How many autosaves to backup - this MUST be variable (Parallel Runner)
  AUTOSAVE_COUNT_MIN      = 2;
  AUTOSAVE_COUNT_MAX      = 10;
  AUTOSAVE_FREQUENCY_MIN  = 600;
  AUTOSAVE_FREQUENCY_MAX  = 3000;
  AUTOSAVE_FREQUENCY      = 600; //How often to do autosave, every N ticks
  AUTOSAVE_ATTACH_TO_CRASHREPORT_MAX = 5; //Max number of autosaves to be included into crashreport
  AUTOSAVE_NOT_MORE_OFTEN_THEN = 10000; //= 10s - Time in ms, how often we can make autosaves. On high speedups we can get IO errors because of too often saves


  CHAT_COOLDOWN           = 500;  //Minimum time in milliseconds between chat messages
  BEACON_COOLDOWN         = 400;  //Minimum time in milliseconds between beacons

  DYNAMIC_HOTKEYS_NUM  = 20; // Number of dynamic hotkeys

var
  HITPOINT_RESTORE_PACE: Word = 100;         //1 hitpoint is restored to units every X ticks (using Humbelum's advice)

const
  //Here we store options that are hidden somewhere in code
  //Unit condition
  CONDITION_PACE             = 10;         //Check unit conditions only once per 10 ticks
  UNIT_STUFFED_CONDITION_LVL = 0.9;        //Unit condition level, until which we allow unit to eat foods
  UNIT_MAX_CONDITION         = 45*60;      //Minutes of life. In KaM it's 45min
  UNIT_MIN_CONDITION         = 6*60;       //If unit condition is less it will look for Inn. In KaM it's 6min
  TROOPS_FEED_MAX            = 0.55;       //Maximum amount of condition a troop can have to order food (more than this means they won't order food)
  UNIT_CONDITION_BASE        = 0.6;        //Base amount of health a unit starts with (measured in KaM)
  UNIT_CONDITION_RANDOM      = 0.1;        //Random jitter of unit's starting health (KaM did not have this, all units started the same)
  TROOPS_TRAINED_CONDITION   = 0.6;        //Condition troops start with when trained (measured from KaM)

  //Units are fed acording to this: (from knightsandmerchants.de tips and tricks)
  //Bread    = +40%
  //Sausages = +60%
  //Wine     = +20% (We changed this to +30% for balance)
  //Fish     = +50%
  BREAD_RESTORE = 0.4;
  SAUSAGE_RESTORE = 0.6;
  WINE_RESTORE = 0.3;
  FISH_RESTORE = 0.5;


  DEFAULT_HITPOINT_RESTORE  = 100;        //1 hitpoint is restored to units every X ticks (using Humbelum's advice)
  TIME_BETWEEN_MESSAGES     = 4*600;      //Time between messages saying house is unoccupied or unit is hungry. In KaM it's 4 minutes

  RANGE_WATCHTOWER_MAX  = 6.99; //Measured in KaM. Distance from the doorway of tower
  RANGE_WATCHTOWER_MIN  = 0; //In KaM towers have no minimum range, they will shoot any unit less than the range

  LINK_RADIUS = 5; //Radius to search for groups to link to after being trained at the barracks (measured from KaM)

  FRIENDLY_FIRE = True; //Whenever archers could kill fellow men with their arrows

  NET_DROP_PLAYER_MIN_WAIT = 30; //Host must wait at least this long before dropping disconnected players
  ANNOUNCE_BUILD_MAP = 30*60*10; //30 minutes
  ANNOUNCE_BATTLE_MAP = 2*60*10; //2 minutes

  RESULTS_UPDATE_RATE = 15;          //Each 1.5 sec
  CHARTS_SAMPLING_FOR_ECONOMY = 150; //Each 15sec
  CHARTS_SAMPLING_FOR_TACTICS = 30;  //Each 3sec, cos average game length is much shorter

  RETURN_TO_LOBBY_SAVE = 'paused';
  DOWNLOADED_LOBBY_SAVE = 'downloaded';

  EXT_SAVE_REPLAY = 'rpl';
  EXT_SAVE_MAIN = 'sav';
  EXT_SAVE_BASE = 'bas';
  EXT_SAVE_MP_MINIMAP = 'smm';

  EXT_FILE_SCRIPT = 'script';

  EXT_SAVE_REPLAY_DOT = '.' + EXT_SAVE_REPLAY;
  EXT_SAVE_MAIN_DOT = '.' + EXT_SAVE_MAIN;
  EXT_SAVE_BASE_DOT = '.' + EXT_SAVE_BASE;
  EXT_SAVE_MP_MINIMAP_DOT = '.' + EXT_SAVE_MP_MINIMAP;

  EXT_FILE_SCRIPT_DOT = '.' + EXT_FILE_SCRIPT;

type
  TKMHandID = {type} ShortInt;
  TKMHandIDArray = array of TKMHandID;
  TKMHandEnabledArray = array [0..MAX_HANDS-1] of Boolean;

const
  PLAYER_NONE = -1; //No player
  PLAYER_ANIMAL = -2; //animals

  // Used to reset on new game start
  OWN_MARGIN_DEF   :Byte = 190;
  OWN_THRESHOLD_DEF:Byte = 126;

var
  //Values are empirical
  //todo: Can move this to AIInfluences as parameter
  OWN_MARGIN   :Byte = 190;
  OWN_THRESHOLD:Byte = 126;


{Cursors}
type
  TKMCursorMode = (
    cmNone,
    cmErase, //Remove player controlled assets (plans, houses) with a confirmation dialog
    cmRoad,
    cmField,
    cmWine,
    cmHouses, // Gameplay

    //Map Editor
    cmElevate, //Height elevation
    cmEqualize, //Height equalization
    cmBrush, //Terrain brush
    cmTiles, // Individual tiles
    cmObjects, //Terrain objects
    cmMagicWater, //Magic water
    cmSelection, //Selection manipulations
    cmUnits, //Units
    cmMarkers, //CenterScreen, FOW, Defence, AIStart, Rally/Cutting Point markers
    cmEyedropper, //Terrain eyedropper
    cmPaintBucket, //PaintBucket - change color(team) for map objects
    cmUniversalEraser, //Universal eraser for units/groups/houses/terrain objects/roads and fields (corn/wine)
    cmRotateTile  //Rotate terrain tile
    );

type
  // How cursor field placing will act (depends on which tile LMB was pressed)
  TKMCursorFieldMode = (
    cfmNone, // Disabled
    cfmPlan, // Placing plans
    cfmErase // Erasing plans
  );

  // Shape types for MapEditor
  TKMMapEdShape = (hsCircle, hsSquare);


const
  MARKER_REVEAL = 1;
  MARKER_DEFENCE = 2;
  MARKER_CENTERSCREEN = 3;
  MARKER_AISTART = 4;
  MARKER_RALLY_POINT = 5;


const
  DirCursorCircleRadius  = 32; //Radius of the direction selector cursor restriction area
  DirCursorNARadius = 20;  //Radius of centeral part that has no direction


type
  TKMGameResultMsg = (//Game result
        gr_Win,           //Player has won the game
        gr_Defeat,        //Player was defeated
        gr_Cancel,        //Game was cancelled (unfinished)
        gr_Error,         //Some known error occured
        gr_Disconnect,    //Disconnected from multiplayer game
        gr_Silent,        //Used when loading savegame from running game (show no screens)
        gr_ReplayEnd,     //Replay was cancelled - return to menu without screens
        gr_MapEdEnd,      //Map Editor was closed - return to menu without screens
        gr_GameContinues);//Game is not finished yet, it is continious


type
  TKMissionMode = (mm_Normal, mm_Tactic);

  TKMAllianceType = (at_Enemy, at_Ally);

  TKMapFolder = (mfSP, mfMP, mfDL);
  TKMapFolderSet = set of TKMapFolder;


const
  MAPS_FOLDER_NAME = 'Maps';
  MAPS_MP_FOLDER_NAME = 'MapsMP';
  MAPS_DL_FOLDER_NAME = 'MapsDL';
  TUTORIALS_FOLDER_NAME = 'Tutorials';
  CAMPAIGNS_FOLDER_NAME = 'Campaigns';
  SAVES_FOLDER_NAME = 'Saves';
  SAVES_MP_FOLDER_NAME = 'SavesMP';


{ Terrain }
type
  TKMTerrainPassability = (
    tpUnused,
    tpWalk,        // General passability of tile for any walking units
    tpWalkRoad,    // Type of passability for Serfs when transporting wares, only roads have it
    tpBuildNoObj,  // Can we build a house on this tile after removing an object on the tile or house near it?
    tpBuild,       // Can we build a house on this tile?
    tpMakeRoads,   // Thats less strict than house building, roads Can be placed almost everywhere where units Can walk, except e.g. bridges
    tpCutTree,     // Can tree be cut
    tpFish,        // Water tiles where fish Can move around
    tpCrab,        // Sand tiles where crabs Can move around
    tpWolf,        // Soil tiles where wolfs Can move around
    tpElevate,     // Nodes which are forbidden to be elevated by workers (house basements, water, etc..)
    tpWorker,      // Like CanWalk but allows walking on building sites
    tpOwn,         // For AI ownership
    tpFactor       // Allows vertex (top left) to be factored as a neighbour in flattening algorithm
  );
  TKMTerrainPassabilitySet = set of TKMTerrainPassability;

  TKMHeightPass = (hpWalking, hpBuilding, hpBuildingMines);

const
  PassabilityGuiText: array [TKMTerrainPassability] of UnicodeString = (
    'Unused',
    'Can walk',
    'Can walk road',
    'Can build without|object or house',
    'Can build',
    'Can make roads',
    'Can cut tree',
    'Can fish',
    'Can crab',
    'Can wolf',
    'Can elevate',
    'Can worker',
    'Can own',
    'Can factor'
  );


type
  TKMWalkConnect = (
    wcWalk,
    wcRoad,
    wcFish, //Required for fisherman finding fish in a pond, NOT for fish movement (uses steering). Updated ONLY on load because water doesn't change.
    wcWork  //CanWorker areas
  );


const
  UID_NONE: Integer = -1; //Would be better to have it 0. But now it's -1 for backwards compatibility


{Units}
type
  TKMUnitType = (ut_None, ut_Any,
    ut_Serf,          ut_Woodcutter,    ut_Miner,         ut_AnimalBreeder,
    ut_Farmer,        ut_Lamberjack,    ut_Baker,         ut_Butcher,
    ut_Fisher,        ut_Worker,        ut_StoneCutter,   ut_Smith,
    ut_Metallurgist,  ut_Recruit,

    ut_Militia,      ut_AxeFighter,   ut_Swordsman,     ut_Bowman,
    ut_Arbaletman,   ut_Pikeman,      ut_Hallebardman,  ut_HorseScout,
    ut_Cavalry,      ut_Barbarian,

    ut_Peasant,      ut_Slingshot,    ut_MetalBarbarian,ut_Horseman,
    //ut_Catapult,   ut_Ballista,

    ut_Wolf,         ut_Fish,         ut_Watersnake,   ut_Seastar,
    ut_Crab,         ut_Waterflower,  ut_Waterleaf,    ut_Duck);

  TKMUnitTypeSet = set of TKMUnitType;

const
  UNIT_MIN = ut_Serf;
  UNIT_MAX = ut_Duck;
  CITIZEN_MIN = ut_Serf;
  CITIZEN_MAX = ut_Recruit;
  WARRIOR_MIN = ut_Militia;
  WARRIOR_MAX = ut_Horseman;
  WARRIOR_EQUIPABLE_MIN = ut_Militia; //Available from barracks
  WARRIOR_EQUIPABLE_MAX = ut_Cavalry;
  HUMANS_MIN = ut_Serf;
  HUMANS_MAX = ut_Horseman;
  ANIMAL_MIN = ut_Wolf;
  ANIMAL_MAX = ut_Duck;

  WARRIORS_IRON = [ut_Swordsman, ut_Arbaletman, ut_Hallebardman, ut_Cavalry];

type
  TKMCheckAxis = (ax_X, ax_Y);

//Used for AI defence and linking troops
type
  TKMGroupType = (gt_Melee, gt_AntiHorse, gt_Ranged, gt_Mounted);
  TKMGroupTypeArray = array [TKMGroupType] of Word;
  TKMGroupTypeSet = set of TKMGroupType;

  TKMArmyType = (atIronThenLeather = 0, atLeather = 1, atIron = 2, atIronAndLeather = 3);

const
  KaMGroupType: array [TKMGroupType] of Byte = (0, 1, 2, 3);

  UnitGroups: array [WARRIOR_MIN..WARRIOR_MAX] of TKMGroupType = (
    gt_Melee,gt_Melee,gt_Melee, //ut_Militia, ut_AxeFighter, ut_Swordsman
    gt_Ranged,gt_Ranged,        //ut_Bowman, ut_Arbaletman
    gt_AntiHorse,gt_AntiHorse,  //ut_Pikeman, ut_Hallebardman,
    gt_Mounted,gt_Mounted,      //ut_HorseScout, ut_Cavalry,
    gt_Melee,                   //ut_Barbarian
    //TPR Army
    gt_AntiHorse,        //ut_Peasant
    gt_Ranged,           //ut_Slingshot
    gt_Melee,            //ut_MetalBarbarian
    gt_Mounted           //ut_Horseman
    {gt_Ranged,gt_Ranged, //ut_Catapult, ut_Ballista,}
    );

  //AI's prefences for training troops
  AITroopTrainOrder: array [TKMGroupType, 1..3] of TKMUnitType = (
    (ut_Swordsman,    ut_AxeFighter, ut_Militia),
    (ut_Hallebardman, ut_Pikeman,    ut_None),
    (ut_Arbaletman,   ut_Bowman,     ut_None),
    (ut_Cavalry,      ut_HorseScout, ut_None));

type
  TKMGoInDirection = (gd_GoOutside=-1, gd_GoInside=1); //Switch to set if unit goes into house or out of it

type
  TKMUnitThought = (th_None, th_Eat, th_Home, th_Build, th_Stone, th_Wood, th_Death, th_Quest, th_Dismiss);

const //Corresponding indices in units.rx
  ThoughtBounds: array [TKMUnitThought, 1..2] of Word = (
  (0,0), (6250,6257), (6258,6265), (6266,6273), (6274,6281), (6282,6289), (6290,6297), (6298,6305), (6314,6321)
  );

  UNIT_OFF_X = -0.5;
  UNIT_OFF_Y = -0.4;

  //Offsetting layers of units we control what goes above or below
  //using smaller values to minimize impact on other objects and keeping withing map bounds
  FLAG_X_OFFSET = 0.01; //Flag is offset to be rendered above/below the flag carrier
  THOUGHT_X_OFFSET = 0.02; //Thought is offset to be rendered always above the flag

  //TileCursors
  TC_OUTLINE = 0;
  TC_BLOCK = 479;
  TC_BLOCK_MINE = 480;
  TC_ENTRANCE = 481;
  TC_BLOCK_ENTRANCE = 482;

type
  TKMUnitTaskType = ( uttUnknown, //Uninitialized task to detect bugs
        uttSelfTrain, uttDeliver,         uttBuildRoad,  uttBuildWine,        uttBuildField,
        uttBuildHouseArea, uttBuildHouse, uttBuildHouseRepair, uttGoHome,    uttDismiss,
        uttGoEat,     uttMining,          uttDie,        uttGoOutShowHungry,  uttAttackHouse,
        uttThrowRock);

  TKMUnitActionName = (uan_Stay, uan_WalkTo, uan_GoInOut, uan_AbandonWalk, uan_Fight, uan_StormAttack, uan_Steer);

  TKMUnitActionType = (uaWalk=120, uaWork, uaSpec, uaDie, uaWork1,
                     uaWork2, uaWorkEnd, uaEat, uaWalkArm, uaWalkTool,
                     uaWalkBooty, uaWalkTool2, uaWalkBooty2, uaUnknown);
  TKMUnitActionTypeSet = set of TKMUnitActionType;

const
  UnitAct: array [TKMUnitActionType] of string = ('uaWalk', 'uaWork', 'uaSpec', 'uaDie', 'uaWork1',
             'uaWork2', 'uaWorkEnd', 'uaEat', 'uaWalkArm', 'uaWalkTool',
             'uaWalkBooty', 'uaWalkTool2', 'uaWalkBooty2', 'uaUnknown');


const
  FishCountAct: array [1..5] of TKMUnitActionType = (uaWalk, uaWork, uaSpec, uaDie, uaWork1);


type
  TKMGatheringScript = (
    gs_None,
    gs_WoodCutterCut, gs_WoodCutterPlant,
    gs_FarmerSow, gs_FarmerCorn, gs_FarmerWine,
    gs_FisherCatch,
    gs_StoneCutter,
    gs_CoalMiner, gs_GoldMiner, gs_IronMiner,
    gs_HorseBreeder, gs_SwineBreeder);

{Houses in game}
type
  //House has 3 basic states: no owner inside, owner inside, owner working inside
  TKMHouseState = (hst_Empty, hst_Idle, hst_Work);
  //These are house building states
  TKMHouseBuildState = (hbs_NoGlyph, hbs_Wood, hbs_Stone, hbs_Done);

  TKMHouseActionType = (
    ha_Work1, ha_Work2, ha_Work3, ha_Work4, ha_Work5, //Start, InProgress, .., .., Finish
    ha_Smoke, ha_Flagpole, ha_Idle,
    ha_Flag1, ha_Flag2, ha_Flag3,
    ha_Fire1, ha_Fire2, ha_Fire3, ha_Fire4, ha_Fire5, ha_Fire6, ha_Fire7, ha_Fire8);
  TKMHouseActionSet = set of TKMHouseActionType;

const
  HouseAction: array [TKMHouseActionType] of string = (
  'ha_Work1', 'ha_Work2', 'ha_Work3', 'ha_Work4', 'ha_Work5', //Start, InProgress, .., .., Finish
  'ha_Smoke', 'ha_FlagShtok', 'ha_Idle',
  'ha_Flag1', 'ha_Flag2', 'ha_Flag3',
  'ha_Fire1', 'ha_Fire2', 'ha_Fire3', 'ha_Fire4', 'ha_Fire5', 'ha_Fire6', 'ha_Fire7', 'ha_Fire8');


{Terrain}
type
  TKMFieldType = (
    ftNone,
    ftRoad,
    ftCorn,
    ftWine,
    ftInitWine //Reset rotation and set grapes ground, but without Grapes yet
    );

  TKMHouseStage = (
    hsNone,        //Nothing, clear area
    hsFence,       //Wooden fence, partially walkable as workers digg it up
    hsBuilt        //Done
  );

  //There are 4 steps in tile blocking scheme:
  // 0. Tile is normally walkable
  // 1. Set the tile as CantBuild
  // 2. Sets the tile as CantWalk to anyone except workers who are performing
  //    the digging task, so they could escape the area.
  //    The Worker will push out any unit on his way.
  //    sidenote: CanElevate is per-vertex property, hence it's not identical to CanWorker
  // 3. Set the tile as fully blocked
  TKMTileLock = (     // CanBuild CanWalk CanWorker CanElevate House Digged Fenced
        tlNone,     // X        X         X       X          -     -      -
        tlFenced,   // -        X         X       X          X     -      X
        tlDigged,   // -        -         X       X          X     X      X
        tlHouse,    // -        -         -       -          X     X      -
        //Used by workers making roads/fields to prevent you from building over them
        tlFieldWork,// -        X         X       X          -     X      -
        tlRoadWork  // -        X         X       X          -     X      -
        );


type
  //Sketch of the goal and message displaying system used in KaM (from scripting point of view anyway)
  //This is very similar to that used in KaM and is quite flexable/expandable.
  //(we can add more parameters/conditions as well as existing KaM ones, possibly using a new script command)
  //Some things are probably named unclearly, please give me suggestions or change them. Goals are the one part
  //of scripting that seems to confuse everyone at first, mainly because of the TGoalStatus. In 99% of cases gs_True and gt_Defeat
  //go together, because the if the defeat conditions is NOT true you lose, not the other way around. I guess it should be called a
  //"survival" conditions rather than defeat.
  //I put some examples below to give you an idea of how it works. Remember this is basically a copy of the goal scripting system in KaM,
  //not something I designed. It can change, this is just easiest to implement from script compatability point of view.

  TKMGoalType = (glt_None = 0,  //Means: It is not required for victory or defeat (e.g. simply display a message)
               glt_Victory, //Means: "The following condition must be true for you to win"
               glt_Survive);//Means: "The following condition must be true or else you lose"
  //Conditions are the same numbers as in KaM script
  TKMGoalCondition = (gc_Unknown0,      //Not used/unknown
                    gc_BuildTutorial,   //Must build a tannery (and other buildings from tutorial?) for it to be true. In KaM tutorial messages will be dispalyed if this is a goal
                    gc_Time,            //A certain time must pass
                    gc_Buildings,       //Storehouse, school, barracks, TownHall
                    gc_Troops,          //All troops
                    gc_Unknown5,        //Not used/unknown
                    gc_MilitaryAssets,  //All Troops, Coal mine, Weapons Workshop, Tannery, Armory workshop, Stables, Iron mine, Iron smithy, Weapons smithy, Armory smithy, Barracks, Town hall and Vehicles Workshop
                    gc_SerfsAndSchools, //Serfs (possibly all citizens?) and schoolhouses
                    gc_EconomyBuildings //School, Inn and Storehouse
                    //We can come up with our own
                    );

  TKMGoalStatus = (gs_True = 0, gs_False = 1); //Weird that it's inverted, but KaM uses it that way

const
  //We discontinue support of other goals in favor of PascalScript scripts
  GoalsSupported: set of TKMGoalCondition =
    [gc_Buildings, gc_Troops, gc_MilitaryAssets, gc_SerfsAndSchools, gc_EconomyBuildings];

  GoalConditionStr: array [TKMGoalCondition] of string = (
    'Unknown 0',
    'Build Tannery',
    'Time',
    'Store School Barracks',
    'Troops',
    'Unknown 5',
    'Military assets',
    'Serfs&Schools',
    'School Inn Store');

//Indexes KM_FormMain.StatusBar
const
  SB_ID_KMR_VER      = 0;
  SB_ID_MAP_SIZE     = 1;
  SB_ID_CURSOR_COORD = 2;
  SB_ID_TILE         = 3;
  SB_ID_TIME         = 4;
  SB_ID_FPS          = 5;
  SB_ID_OBJECT       = 6;
  SB_ID_CTRL_ID      = 7;

type
  TKMMapSize = (msNone, msXS, msS, msM, msL, msXL, msXXL);

const
  MAP_SIZE_ENUM_MIN = msXS;
  MAP_SIZE_ENUM_MAX = msXXL;

type
  TKMMapEdLayer = (
    mlObjects,
    mlHouses,
    mlUnits,
    mlOverlays,
    mlDeposits,
    mlMiningRadius,
    mlTowersAttackRadius,
    mlUnitsAttackRadius,
    mlDefences,
    mlRevealFOW,
    mlCenterScreen,
    mlAIStart,
    mlSelection,
    mlWaterFlow,
    mlTileOwner,
    mlMapResize);  //Enum representing mapEditor visible layers
  TKMMapEdLayerSet = set of TKMMapEdLayer;                                   //Set of above enum

const
  //Colors available for selection in multiplayer
  MP_COLOR_COUNT = 22;
  MP_TEAM_COLORS: array [1..MP_COLOR_COUNT] of Cardinal = (
  $FF0000EB, // Red
  $FF076CF8, // Orange
  $FF00B5FF, // Gold
  $FF07FFFF, // Lauenburg yellow
  $FF0EC5A2, // Lime green
  $FF07FF07, // Neon green
  $FF00A100, // Bright green
  $FF134B00, // Dark green
  $FF7A9E00, // Teal
  $FFFACE64, // Sky blue
  $FF973400, // Blue
  $FFCB3972, // Violet (Amethyst)
  $FF720468, // Purple
  $FFDE8FFB, // Pink
  $FFFF07FF, // Magenta
  $FF4A00A8, // Dark pink
  $FF00005E, // Maroon
  $FF103C52, // Brown
  $FF519EC9, // Tan
  $FFFFFFFF, // White
  $FF838383, // Grey
  $FF1B1B1B  // Black
  );

  //Players colors, as they appear in KaM when the color is not specified in the script, copied from palette values.
  //Using these as the defaults when loading the script means the colors will be the same as KaM when not defined.
  //Default IDs from KaM:
  {229, //Red
  36,  //Cyan
  106, //Green
  20,  //Magenta
  233, //Yellow
  213, //Grey
  3,   //Black
  3,   //Black
  255  //White}
  DefaultTeamColors: array [0..MAX_HANDS-1] of Cardinal = (
  $FF0707FF, //Red
  $FFE3BB5B, //Cyan
  $FF27A700, //Green
  $FFFF67FF, //Magenta
  $FF07FFFF, //Yellow
  $FF577B7B, //Grey
  $FF2383FB, //Orange
  $FFFF0707, //Blue
  $FF0BE73F, //Light green
  $FF720468, //Purple
  $FFFFFFFF, //White
  $FF000000  //Black
  );

  //Interface colors
  icGreen  = $FF00C000;
  icYellow = $FF07FFFF;
  icOrange = $FF0099FF;
  icRed    = $FF0707FF;
  icBlue   = $FFFF0707;
  icCyan   = $FFFFFF00;

  icTransparent = $00;
  icDarkGray = $FF606060;
  icDarkGrayTrans = $60606060;
  icDarkestGrayTrans = $80303030;
  icGray = $FF808080;
  icGray2 = $FF888888;
  icLightGray = $FFA0A0A0;
  icLightGray2 = $FFD0D0D0;
  icLightGrayTrans = $80A0A0A0;
  icWhite = $FFFFFFFF;
  icBlack = $FF000000;
  icLightCyan   = $FFFFFF80;
  icLightOrange = $FF80CCFF;
  icLightRed   = $FF7070FF;
  icLight2Red   = $FFB0B0FF;
  icDarkCyan   = $FFB0B000;

  icPink = $FFFF00FF;
  icDarkPink = $FFAA00AA;

  icSteelBlue = $FFA56D53;

  icRoyalYellow = $FF4AC7FF;
  icGoldenYellow = $FF00B0FF;
  icAmberBrown = $FF006797;
  icDarkGoldenRod = $FF0080B0; // brown shade color

  // Interface colors (by usage)
  clPingLow = icGreen;
  clPingNormal = icYellow;
  clPingHigh = icOrange;
  clPingCritical = icRed;

  clFpsCritical = icRed;
  clFpsLow = icOrange;
  clFpsNormal = icYellow;
  clFpsHigh = icGreen;

  clTextSelection = icSteelBlue;

  clMPSrvDetailsGameInfoFont = icLightGray;
  clStatsUnitDefault = icWhite;
  clStatsUnitMissingHL = $FF0080FF;

  clMessageUnitUnread = icGoldenYellow;
  clMessageUnitUnreadHL = icRoyalYellow;
  clMessageUnitRead = icDarkGoldenRod;
  clMessageUnitReadHL = icAmberBrown;

  clLobbyOpponentAll = icRoyalYellow;
  clLobbyOpponentAllHL = icAmberBrown;

  clListSelShape = $88888888;
  clListSelOutline = icWhite;
  clListSelShapeUnfocused = $66666666;
  clListSelOutlineUnfocused = icLightGray;
  clListSeparatorShape = icDarkGray;

  clMapEdBtnField = icYellow;
  clMapEdBtnWine = icYellow;

  clChartHighlight = icPink;
  clChartHighlight2 = icDarkPink;
  clChartDashedHLn = icDarkGray;
  clChartDashedVLn = icDarkGrayTrans;
  clChartPeacetimeLn = icDarkGoldenRod;
  clChartPeacetimeLbl = icGoldenYellow;
  clChartSeparator = icTransparent;

  clChkboxOutline = icLightGrayTrans;

  clPlayerSelf = icRed;
  clPlayerAlly = icYellow;
  clPlayerEnemy = icCyan;

//  clGameSelf = icRed;
//  clGameAlly = icYellow;
//  clGameEnemy = icCyan;

var
  ExeDir: UnicodeString;

implementation

initialization
begin
  GAME_REVISION := AnsiString('r' + IntToStr(GAME_REVISION_NUM));
  GAME_VERSION := GAME_VERSION_PREFIX + GAME_REVISION + GAME_VERSION_POSTFIX;
  NET_PROTOCOL_REVISON := GAME_REVISION;     //Clients of this version may connect to the dedicated server
end;

end.

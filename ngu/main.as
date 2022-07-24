const bool DEV_MODE = true;

// used to rate-limit game type log msgs
uint64 lastPrint = 0;

const string GIVE_UP_ACTION_NAME = "Give up";
const string RESPAWN_ACTION_NAME = "Respawn";
/* player inputs count = 15 for KB and 19 for GamePad */

const string PLUGIN_TITLE = "Never Give Up!";

string keyBoundToGiveUp;

string gameMode;
string lastGameMode;

bool isGiveUpBound = true;

string[] giveUpBindings;
string prevBindings = "";


CTrackMania@ GetTmApp() {
   return cast<CTrackMania>(GetApp());
}


UnbindPrompt unbindPrompt = UnbindPrompt();


void Main() {
#if TMNEXT
   auto app = GetTmApp();
   startnew(LoopCheckBinding);
   startnew(CoroInitBindings);
   IsGiveUpBound();

   while (unbindPrompt is null) {
      yield();
   }

#if DEV
   DebugPrintBindings();
#endif

#else
   warn("Never Give Up is only compatible with TM2020. It doesn't do anything in other games.");
   UI::ShowNotification("Never Give Up is only compatible with TM2020.", "It doesn't do anything in other games.", vec4(.4, .2, .2, .7));
#endif
}

void CoroInitBindings() {
   // NGU can't do much if the bindings aren't initialized, so one second after the plugin is loaded, let's make sure they are initialized.
   sleep(1000);
   gi.GetManiaPlanetScriptApi().InputBindings_UpdateList(CGameManiaPlanetScriptAPI::EInputsListFilter::All, GetFirstPadGiveUpBoundOrDefault());
}

void LoopCheckBinding() {
   while (true) {
      isGiveUpBound = IsGiveUpBound();
      sleep(60); // ~16.7x per second at most
   }
}

bool InputBindingsInitialized() {
   auto mpsa = gi.GetManiaPlanetScriptApi();
   if (mpsa is null) return false;
   if (mpsa.InputBindings_Bindings.Length < 7) return false;
   return true;
}

uint GetActionIndex(const string &in actionName) {
   auto mpsa = gi.GetManiaPlanetScriptApi();
   for (uint i = 0; i < mpsa.InputBindings_ActionNames.Length; i++) {
      // debugPrint("mpsa.InputBindings_ActionNames[i]: " + mpsa.InputBindings_ActionNames[i]);
      if (string(mpsa.InputBindings_ActionNames[i]) == actionName)
         return i;
   }
   throw("Could not find action index for action name: " + actionName);
   return 0xffffff;
}

bool HasOkayPad() {
   auto pads = GetTmApp().InputPort.Script_Pads;
   for (uint i = 0; i < pads.Length; i++) {
      if (CheckPadOkaySettings(pads[i])) return true;
   }
   return false;
}

bool IsGiveUpBound() {
   // seems like this is somewhat problematic, so just use the other way that should be more robust.
   // return IsGiveUpBoundAux();
   auto app = GetTmApp();
   auto mpsa = gi.GetManiaPlanetScriptApi();
   if (!InputBindingsInitialized()) {
      return IsGiveUpBoundAux();
   }
   auto pads = app.InputPort.Script_Pads;
   giveUpBindings.RemoveRange(0, giveUpBindings.Length);
   for (uint i = 0; i < pads.Length; i++) {
      auto pad = pads[i];
      if (!CheckPadOkaySettings(pad)) continue;
      mpsa.InputBindings_UpdateList(CGameManiaPlanetScriptAPI::EInputsListFilter::All, pad);
      uint giveUpIx = GetActionIndex(GIVE_UP_ACTION_NAME);
      string currBindings = string(mpsa.InputBindings_Bindings[giveUpIx]);
      if (currBindings.Length > 0) {
         giveUpBindings.InsertLast(currBindings);
      }
   }
   if (giveUpBindings.Length > 0) {
      return true;
   }
   return IsGiveUpBoundAux(); // fallback
}

// hmm, this doesn't work in menus -- mb b/c GetActionBinding checks "Vehicle"?
bool IsGiveUpBoundAux() {
   auto app = GetTmApp();
   auto pads = app.InputPort.Script_Pads;
   auto _in = app.MenuManager.MenuCustom_CurrentManiaApp.Input;
   string binding;
   giveUpBindings.RemoveRange(0, giveUpBindings.Length);
   CInputScriptPad@ firstPad;
   for (uint i = 0; i < pads.Length; i++) {
      auto pad = app.InputPort.Script_Pads[i];
      if (!CheckPadOkaySettings(pad)) continue;
      binding = _in.GetActionBinding(pad, "Vehicle", "GiveUp");
      if (binding != "") {
         giveUpBindings.InsertLast(binding);
         if (firstPad !is null) {
            @firstPad = pad;
         }
      }
   }
   binding = array2str(giveUpBindings);
   if (prevBindings != binding) {
      trace("GiveUp bindings: " + binding);
      prevBindings = binding;
   }
   return giveUpBindings.Length > 0;
}


bool CheckPadOkaySettings(CInputScriptPad@ pad) {
   if (Setting_PadType == PadType::Keyboard)
      return pad.Type == CInputScriptPad::EPadType::Keyboard;
   if (Setting_PadType == PadType::Mouse)
      return pad.Type == CInputScriptPad::EPadType::Mouse;
   if (Setting_PadType == PadType::GamePad)
      return pad.Type == CInputScriptPad::EPadType::Generic
         || pad.Type == CInputScriptPad::EPadType::XBox
         || pad.Type == CInputScriptPad::EPadType::PlayStation
         || pad.Type == CInputScriptPad::EPadType::Vive
         ;
   return true;
}

// CInputScriptPad@ firstPadGUBound;
int firstPadGUBoundIx = -1;
CInputScriptPad@ GetPadWithGiveUpBound() {
      // todo check setting for controller
   auto app = GetTmApp();
   auto pads = app.InputPort.Script_Pads;
   auto _in = app.MenuManager.MenuCustom_CurrentManiaApp.Input;
   string binding;
   for (uint i = 0; i < pads.Length; i++) {
      auto pad = app.InputPort.Script_Pads[i];
      binding = _in.GetActionBinding(pad, "Vehicle", "GiveUp");
      if (binding != "" && CheckPadOkaySettings(pad)) {
         // @firstPadGUBound = pad;
         firstPadGUBoundIx = int(i);
         return pad;
      }
   }
   firstPadGUBoundIx = -1;
   return null;
}

CInputScriptPad@ GetFirstPadGiveUpBoundOrDefault() {
   // if (firstPadGUBound !is null) {
   //    return firstPadGUBound;
   // }
   auto app = GetTmApp();
   auto pads = app.InputPort.Script_Pads;
   if (firstPadGUBoundIx > 0 && firstPadGUBoundIx < int(pads.Length)) {
      auto pad = pads[firstPadGUBoundIx];
      if (CheckPadOkaySettings(pad))
         return pad;
   } else if (firstPadGUBoundIx > 0) {
      // we used to have a pad but don't anymore, so use the other function and re-cache.
      return GetPadWithGiveUpBound();
   }
   CInputScriptPad@ mouse;
   for (uint i = 0; i < pads.Length; i++) {
      // todo check setting for controller
      auto pad = app.InputPort.Script_Pads[i];
      // don't return the mouse first -- skip and return at end if no other pads
      if (pad.Type == CInputScriptPad::EPadType::Mouse) {
         @mouse = pad;
      } else if (CheckPadOkaySettings(pad)) {
         return pad;
      }
   }
   return mouse;
}



void OnSettingsChanged() {
   unbindPrompt.OnSettingsChanged();
   auto mpsa = gi.GetManiaPlanetScriptApi();
   if (mpsa !is null) {
      mpsa.InputBindings_UpdateList(CGameManiaPlanetScriptAPI::EInputsListFilter::All, GetFirstPadGiveUpBoundOrDefault());
   }
}

void RenderMenu() {
   unbindPrompt.RenderMenu();
}


void _Render() {
   unbindPrompt.Draw();
}

void RenderInterface() {
   if (!Setting_RenderIfUiHidden) {
      _Render();
   }
}

void Render() {
   if (Setting_RenderIfUiHidden) {
      _Render();
   }
   Wizard::Render();
}

bool ctrlDown = false;
bool shiftDown = false;
bool scutKeyDown = false;

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
   switch (key) {
      case VirtualKey::Control: ctrlDown = down; break;
      case VirtualKey::Shift: shiftDown = down; break;
   }
   if (key == Setting_ShortcutKey)
      scutKeyDown = down;

   if (Setting_Enabled && State_CurrentlyVisible && ctrlDown && shiftDown && scutKeyDown) {
      ctrlDown = shiftDown = scutKeyDown = false;
      TriggerRebindPrompt();
   }

   return UI::InputBlocking::DoNothing;
}


void TriggerRebindPrompt() {
   if (isGiveUpBound) {
      auto pad = GetPadWithGiveUpBound();
      gi.BindInput(GetActionIndex(RESPAWN_ACTION_NAME), pad);
   } else {
      auto pad = GetFirstPadGiveUpBoundOrDefault();
      gi.BindInput(GetActionIndex(GIVE_UP_ACTION_NAME), pad);
   }
}


CTrackManiaNetwork@ getNetwork() {
   return cast<CTrackManiaNetwork>(GetTmApp().Network);
}

CTrackManiaNetworkServerInfo@ getServerInfo() {
   return cast<CTrackManiaNetworkServerInfo>(getNetwork().ServerInfo);
}


bool IsRankedOrCOTD() {
   // borrowed method for checking game mode from: https://github.com/chipsTM/tm-cotd-stats/blob/main/src/COTDStats.as
   auto app = cast<CTrackMania>(GetApp());
   auto network = cast<CTrackManiaNetwork>(app.Network);
   if (network is null) { return false; }
   auto server_info = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);
   if (server_info is null) { return false; }

   // we want to allow resets when in the warm-up phase.
   // note: This seems to always be false in TM_KnockoutDaily_Online
   // bool isWarmUp = server_info.IsWarmUp;
   const bool isWarmUp = false;
   bool ret = false;

   if (app.CurrentPlayground !is null && !isWarmUp) {
      gameMode = server_info.CurGameModeStr;
      ret =
         ( false  // this `false` is just to make the below ORs line up nicely (for easy commenting)
         || (Setting_BlockDelCotd   && gameMode == "TM_KnockoutDaily_Online")
         || (Setting_BlockDelKO     && gameMode == "TM_Knockout_Online")
         || (Setting_BlockDelRanked && gameMode == "TM_Teams_Matchmaking_Online")
         || (gameMode == Settings_BlockDelCustom1)
         || (gameMode == Settings_BlockDelCustom2)
         || (gameMode == Settings_BlockDelCustom3)
         || ("*" == Settings_BlockDelCustom1)
         || ("*" == Settings_BlockDelCustom2)
         || ("*" == Settings_BlockDelCustom3)
         );
      if (lastGameMode != gameMode) {
         lastGameMode = gameMode;
         unbindPrompt.OnNewMode();
      }
   }

   return ret;
}


// TM_TimeAttackDaily_Online -- COTD during qualifier (we want to allow 'give up' here)
// TM_KnockoutDaily_Online -- COTD during KO
// TM_Knockout_Online -- Server knockout mode
// TM_Teams_Matchmaking_Online -- Ranked

// * don't do these ones

// TM_Royal_Online -- royal during Super Royal qualis; Super Royal Finals; (?? normally, too ??)
// TM_Campaign_Local -- local campaign, local TOTD

// ? not sure about whether to enable/disable for these -- can be added as custom tho
// TM_Cup_Online -- "cup" game format on server
// Champion (mb TM_Champion_Online) -- a guess -- not sure if this even exists
// TM_Teams_Online -- teams, first points to 100 by default
// TM_Rounds_Online
// TM_TimeAttack_Online
// TM_Champion_Online (not sure what this is)
// TM_Laps_Online

void DebugPrintBindings() {
   print("\\$29f" + 'Bindings:');
   MwFastBuffer<wstring> bs = GameInfo().GetManiaPlanetScriptApi().InputBindings_Bindings;
   MwFastBuffer<wstring> as = GameInfo().GetManiaPlanetScriptApi().InputBindings_ActionNames;
   for (uint i = 0; i < bs.Length; i++) {
      print("  \\$39f" + string(as[i]) + ": " + string(bs[i]));
   }
}

void debugPrint(const string &in msg) {
   print("\\$29f" + msg);
}

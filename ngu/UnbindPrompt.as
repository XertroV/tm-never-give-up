const int _N_ICONS = 25;

const int _width = 300;
const float _font_size = _width / 5;
const int _window_height = 45;
const vec2 _UNBIND_WINDOW_DIMS = vec2(_width, _window_height);
// const vec2 _UNBIND_WINDOW_DIMS = vec2(150, 75);
const vec2 _UNBIND_TEXT_XY = vec2(_width, _width * .3);

#if DEV
const uint REQ_TIME_IN_GAME = 7000;
#else
const uint REQ_TIME_IN_GAME = 10000;
#endif

const float _UNBIND_TEXT_FONT_SIZE = 24.;
const float _UNBIND_TITLE_FONT_SIZE = 20.;

const string unbind = "Unbind";
const string rebind = "Rebind";

const float TAU = Math::Asin(-1) * 2;

const vec4 _WHITE = vec4(1,1,1,2);

GameInfo@ gi = GameInfo();

enum LastAction {
    NoAction,
    UiManuallyClosed,
    // more?
}

enum ShowUI {
    No,
    Unbind,
    Rebind,
}


vec2 _UnbindWindowDims() {
    return _UNBIND_WINDOW_DIMS * vec2(Setting_WindowScale, 1);
}

vec2 _UnbindTextXY() {
    return _UNBIND_TEXT_XY * Setting_WindowScale;
}

string UnbindBtnMsg() {
    return isGiveUpBound ? "Bind 'Give Up' to 'Respawn'" : "Rebind 'Give Up'";
}

int prevUiSequence = 0;
int lastUiSequence = 0;
int timeInGame = 0;
int lastNow = 0;
bool uiDialogSafe = false; // experimental
// note: can also check game time left to avoid allowing clicking before time is too low

bool startedLoopTrackGameUiSeq = false;
void LoopTrackGameUiSeq() {
    if (startedLoopTrackGameUiSeq) return;
    startedLoopTrackGameUiSeq = true;

    while (true) {
        prevUiSequence = lastUiSequence;
        lastUiSequence = gi.GetPlaygroundFstUISequence();
        if (lastNow > 0)
            timeInGame += Time::Now - lastNow;
        if (prevUiSequence != lastUiSequence) {
            trace("UISequence: " + lastUiSequence + " (previously: " + prevUiSequence + ")");
            // if (!gi.GetManiaPlanetScriptApi().Dialog_IsFinished) {
            if (gi.app.Operation_InProgress) {
                warn("Running Operation_Abort");
                gi.app.Operation_Abort();
                /* this doesn't work more than once, but going from 1->4 and calling this immediately seems to allow more time to cancel dialog.
                   gi.UnbindInputDevice(GetPadWithGiveUpBound()); // GetPadWithGiveUpBound() // null
                */
            }
        }
        if (!gi.InGame() || gi.IsLoadingScreen()) {
            timeInGame = lastNow = 0;
            uiDialogSafe = false;
        } else {
            if ((lastUiSequence == 1 || lastUiSequence == 2) && prevUiSequence > 1) {
                // I think the dialog is always safe after this point, mb?
                uiDialogSafe = true;
            } else if (lastUiSequence > 2 || lastUiSequence == 0) {
                uiDialogSafe = false;
            }
        }

        lastNow = Time::Now;
        yield();
    }
}


class UnbindPrompt {
    string sessionIcon;

    LastAction lastAction = NoAction;

    UI::Font@ inlineTitleFont;
    int nvgFont;
    int nvgBoldFont;

    // flag to track whether giveup was bound last frame
    bool last_giveUpBound = true;
    // flag for tracking if we unbound giveUp this map/session
    bool session_giveUpUnbound = false;

    UnbindPrompt() {
        State_hasBeenInGame = false;
        // set the icon for this session.
        sessionIcon = GetIcon(Time::Now);
        @inlineTitleFont = UI::LoadFont("DroidSans.ttf", 26, -1, -1, true, true);
        nvgFont = nvg::LoadFont("DroidSans.ttf", true, true);
        nvgBoldFont = nvg::LoadFont("DroidSans-Bold.ttf", true, true);

        // set up state stuff
        OnNewMode();
        startnew(LoopTrackGameUiSeq);
    }


    // do icon stuff to title -- simple atm but could be more complex / interesting later.
    string IconifyTitle(string _title, bool addPadding = false) {
        if (addPadding) {
            // the padding strings help the icon bit to render nicely with the other text at this font size.
            return " " + sessionIcon + "   " + _title;
        }
        return sessionIcon + " " + _title;
    }

    void Draw() {
        // never draw if disabled or not currently visible
        if (!Setting_Enabled || !State_CurrentlyVisible) {
            return;
        }

        /* don't activate in first 60s of booting up b/c it'll look
           like controls are not bound.
        */

        bool show = false;

        bool appropriateMatch = IsRankedOrCOTD();
        bool inGame = gi.InGame();
        State_hasBeenInGame = State_hasBeenInGame || inGame;
        bool inMenu = gi.InMainMenu();
        bool isLoading = gi.IsLoadingScreen();
        bool enoughTimeLeft = gi.GameTimeMsLeft() > 4000;
        bool appropriateUiSeq = uiDialogSafe || (lastUiSequence == 1 && timeInGame > REQ_TIME_IN_GAME);
        appropriateUiSeq = appropriateUiSeq && enoughTimeLeft;
        bool inputsInitialized = InputBindingsInitialized();

        // don't show up before we've ever joined a game; unless we show the UI most of the time anyway
        if (!State_hasBeenInGame && Setting_HideWhenIrrelevant && !GetLatestWizardShouldRun()) {
            return;
        }

        /* to start with, we want to show if we're in an appropriate match + bound */
        show = show || (appropriateMatch && isGiveUpBound && appropriateUiSeq);

        /* show if we are in a game-mode that we should have giveUp bound but it is not. */
        show = show || (inGame && !appropriateMatch && !isGiveUpBound && appropriateUiSeq);

        show = show || (inMenu && !isGiveUpBound);

        show = show && HasOkayPad();  // only show if we have an appropriate pad

        // if HWI is false and WizardShouldRun is true, then hideWhenIrrelevant is false.
        bool hideWhenIrrelevant = !(!Setting_HideWhenIrrelevant || GetLatestWizardShouldRun());
        bool isPreview = GetLatestWizardShouldRun();
        show = show || isPreview;

        /* show always if this is false; but not if it's unsafe */
        show = show || (!hideWhenIrrelevant && (appropriateUiSeq || inMenu));

        if (last_giveUpBound && !isGiveUpBound) {
            session_giveUpUnbound = true;
        }

        last_giveUpBound = isGiveUpBound;

        /* never show when inputs aren't initd */
        show = show && inputsInitialized;

        if (!show) return;

        auto app = GetTmApp();

        // setup -- settings and prep flags
        auto _pos = Setting_Pos;
        // auto _dims = Setting_Dims;
        auto _locked = Setting_PromptLocked;
        int _flags = 0
                   | UI::WindowFlags::NoTitleBar
                   | UI::WindowFlags::NoCollapse
                //    | UI::WindowFlags::AlwaysAutoResize
                   | UI::WindowFlags::NoScrollbar
                   | UI::WindowFlags::NoScrollWithMouse
                   | UI::WindowFlags::NoResize
                   | (_locked ? (UI::WindowFlags::NoMove | UI::WindowFlags::NoResize) : 0)
                //    | UI::WindowFlags::MenuBar
                //    | UI::WindowFlags::NoDocking
                ;
        _flags |= UI::IsOverlayShown() ? 0 : UI::WindowFlags::NoInputs;

        // draw window
        UI::SetNextWindowPos(int(_pos.x), int(_pos.y), UI::Cond::Appearing);
        string _title = IconifyTitle(PLUGIN_TITLE, true);
        if (isPreview) _title += " (Preview)";

        // window styles
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 0.);

        // window
        UI::Begin(_title, Setting_Enabled, _flags);

        UI::SetWindowSize(_UnbindWindowDims(), UI::Cond::Always);

        Setting_Pos = UI::GetWindowPos();
        Setting_Pos.x = Math::Max(0, Setting_Pos.x);
        UI::SetWindowPos(Setting_Pos);

        int cols = 4;
#if DEV
        cols += 1;
#endif
        string msg;  // button text
        if (UI::BeginChild("ngu-header")) {
            if (UI::BeginTable("header", cols, UI::TableFlags::SizingStretchProp)) {
                for (int i = 0; i < cols-2; i++) UI::TableSetupColumn('', UI::TableColumnFlags::WidthStretch);
                for (int i = 0; i < 2; i++) UI::TableSetupColumn('btns', UI::TableColumnFlags::WidthFixed);
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::PushFont(inlineTitleFont);
                UI::Text(_title);
                UI::PopFont();

#if DEV
                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text('UiSeq:' + lastUiSequence);
#endif

                UI::TableNextColumn();
                // if (UI::IsOverlayShown()) {
                    msg = UnbindBtnMsg();
                    if (MDisabledButton(gi.app.Operation_InProgress, msg)) {
                        TriggerRebindPrompt();
                    }

                    UI::TableNextColumn();
                    auto lockToggle = !Setting_PromptLocked ? Icons::Unlock : Icons::Lock;
                    auto lockToggleBtn = UI::Button(lockToggle);
                    if (lockToggleBtn) {
                        // clicked lock/unlock
                        Setting_PromptLocked = !Setting_PromptLocked;
                    }
                    // backwards order from icons (icons show state, tooltip shows function)
                    AddSimpleTooltip((!Setting_PromptLocked ? "Lock" : "Unlock") + " this window.");

                    UI::TableNextColumn();
                    // auto visibleIcon = Icons::EyeSlash;
                    // auto visibleIcon = Icons::Eye;
                    auto visibleIcon = Icons::Times;
                    if (UI::Button(visibleIcon)) {
                        // clicked hide
                        State_CurrentlyVisible = false;
                    }
                    AddSimpleTooltip("Hide until next time you should unbind.");
                // } else {
                //     UI::AlignTextToFramePadding();
                //     UI::Text("\\$f81Show UI/Overlay for buttons.");
                // }

                UI::EndTable();
            }
        }
        UI::EndChild();

        // nvg stuff after ImGui, but before we End() so that we can do buttons and things, still.
        DrawUnbindMain(msg);

        UI::End();

        UI::PopStyleVar(1);
    }

    void OnNewMode() {
        State_CurrentlyVisible = true;

        // log updated gameMode
        string p = gameMode == "" ? "<null>" : gameMode;
        trace("Changing game mode to: " + p);
    }

    void DrawUnbindMain(const string &in msg) {
        nvg::Reset();

        auto _pos = Setting_Pos;
        auto _wDims = _UnbindWindowDims();
        auto _ubTxtXY = _UnbindTextXY();

        auto mainMsgHeight = _wDims.y + 1.6 * _ubTxtXY.y;
        auto bottomOfMainMsg = _pos.y + mainMsgHeight;
        auto auxMsgHeight = _wDims.y / 2 * Setting_WindowScale;

        // bg rectangle
        auto t = Time::get_Now() / 500.;
        auto bgRed = Math::Sin(t) / 2. + .5;
        // auto bgAlpha = (1 - bgRed) / 2 + .5;
        auto bgAlpha = 1;
        auto bgGreen = Math::Sin(t + TAU / 3) / 2. + .5;
        auto bgBlue = Math::Sin(t + 2 * TAU / 3) / 2. + .5;
        auto bgColor = vec4(bgRed, bgGreen, bgBlue, bgAlpha) * .8;

        nvg::BeginPath();
        nvg::Rect(_pos.x, _pos.y, _ubTxtXY.x, mainMsgHeight);
        nvg::FillColor(bgColor);
        nvg::Fill();
        nvg::ClosePath();

        nvg::StrokeColor(vec4(1, 0, 0, 0));
        nvg::FillColor((_WHITE - bgColor) * vec4(.1, .1, .1, 1));
        // nvg::StrokeWidth(20);  // stroke on text doens't seem to work :(
        // nvg::Stroke();
        nvg::FontFace(nvgBoldFont);
        nvg::FontSize(_font_size * Setting_WindowScale);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::TextBox(_pos.x, _wDims.y + _pos.y + _ubTxtXY.y/2, _ubTxtXY.x, (isGiveUpBound ? unbind : rebind).ToUpper() + "\n'GIVE UP'");

        // msg underneath with bindings
        nvg::BeginPath();
        nvg::Rect(_pos.x, bottomOfMainMsg, _ubTxtXY.x, auxMsgHeight * 2.0);
        nvg::FillColor(vec4(0,0,0,.9));
        nvg::Fill();
        nvg::ClosePath();

        // giveUpBindings
        nvg::FillColor(_WHITE);
        nvg::FontFace(nvgFont);
        nvg::FontSize(14 * Setting_WindowScale);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::TextBox(_pos.x, bottomOfMainMsg + auxMsgHeight/2, _ubTxtXY.x, "Currently bound: " + array2str(giveUpBindings));
        nvg::TextBox(_pos.x, bottomOfMainMsg + auxMsgHeight*1.5, _ubTxtXY.x, msg + ": Ctrl + Shift + " + VirtKeyToString(Setting_ShortcutKey));
        // nvg::TextBox(_pos.x, bottomOfMainMsg + auxMsgHeight*1.5, _ubTxtXY.x, (isGiveUpBound ? unbind : rebind) + " Shortcut: Ctrl+Shift+" + VirtKeyToString(Setting_ShortcutKey));
    }

    void RenderMenu() {
        if (UI::MenuItem(IconifyTitle(PLUGIN_TITLE), "", Setting_Enabled)) {
            Setting_Enabled = !Setting_Enabled;
        }
    }


    void OnSettingsChanged() {
    }


    /*
    Other functions
    */


    // we only run this once on init
    string GetIcon(uint nonce) {
        string[] _icons = {
            Icons::FighterJet,
            Icons::Bolt,
            Icons::Exclamation,
            Icons::Anchor,
            Icons::FireExtinguisher,
            Icons::Shield,
            Icons::Rocket,
            Icons::LevelUp,
            Icons::Rebel,
            Icons::Empire,
            Icons::SpaceShuttle,
            Icons::PaperPlane,
            Icons::Bomb,
            Icons::Heartbeat,
            Icons::Motorcycle,
            Icons::PaperPlaneO,
            Icons::BirthdayCake,
            Icons::BalanceScale,
            Icons::InternetExplorer,
            Icons::Firefox,
            Icons::FortAwesome,
            Icons::Expand,
            Icons::Sun,
            Icons::Kenney::Flag,
            Icons::Kenney::HeartO
        };

        // print("_icons.Length: " + _icons.Length);
        // print("nonce: " + nonce);
        // print("nonce % _N_ICONS: " + nonce % _N_ICONS);

        if (_icons.Length != _N_ICONS) {
            string errMsg = "Assertion failed: _icons.Length != _N_ICONS (" + _icons.Length + " != " + _N_ICONS + ")";
            // error(errMsg);
            throw(errMsg);
        }

        // assume the nonce was random enough and take the mod to pick an icon.
        return _icons[nonce % _N_ICONS];
    }

}

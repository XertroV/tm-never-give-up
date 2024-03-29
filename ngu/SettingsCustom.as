const uint N_CUSTOM_FIELDS = 3;

// todo: implementation for the below

[Setting hidden]
string Settings_BlockDelCustom1 = "";
[Setting hidden]
string Settings_BlockDelCustom2 = "";
[Setting hidden]
string Settings_BlockDelCustom3 = "";

string[] Settings_BlockDelCustoms; // [Settings_BlockDelCustom1, Settings_BlockDelCustom2, Settings_BlockDelCustom3];

void RenderSettingsCustomGameModes() {
    if (UI::IsWindowAppearing()) {
        // init code
        Settings_BlockDelCustoms.InsertAt(0, Settings_BlockDelCustom1);
        Settings_BlockDelCustoms.InsertAt(1, Settings_BlockDelCustom2);
        Settings_BlockDelCustoms.InsertAt(2, Settings_BlockDelCustom3);
    }
    Settings_BlockDelCustoms.RemoveRange(0, Settings_BlockDelCustoms.Length);
    Settings_BlockDelCustoms.InsertLast(Settings_BlockDelCustom1);
    Settings_BlockDelCustoms.InsertLast(Settings_BlockDelCustom2);
    Settings_BlockDelCustoms.InsertLast(Settings_BlockDelCustom3);

    bool changed = false;
    string newVal = "";
    for (uint i = 0; i < N_CUSTOM_FIELDS; i++) {
        UI::Text("Custom Mode " + (i+1) + " to block 'Give up' in (empty for none; '*' for any)");
        // UI::LabelText goes in the RHS column (values are in the LHS column)
        // UI::LabelText("Custom Mode " + (i+1) + " to block 'Give up' in (empty for none)", Settings_BlockDelCustoms[i]);
        newVal = UI::InputText("Custom Mode " + (i+1), Settings_BlockDelCustoms[i], changed);
        Settings_BlockDelCustoms[i] = newVal;
    }

    Settings_BlockDelCustom1 = Settings_BlockDelCustoms[0];
    Settings_BlockDelCustom2 = Settings_BlockDelCustoms[1];
    Settings_BlockDelCustom3 = Settings_BlockDelCustoms[2];
}


[SettingsTab name="Custom Modes"]
void RenderSettingsCustomModesTab() {
    Settings_BlockDelCustoms.InsertAt(0, Settings_BlockDelCustom1);
    Settings_BlockDelCustoms.InsertAt(1, Settings_BlockDelCustom2);
    Settings_BlockDelCustoms.InsertAt(2, Settings_BlockDelCustom3);

    UI::TextWrapped(
        "Add custom game modes to block 'Give up'.\n"
        "'*'' is a special value: if any of these modes are just '*', then all game modes will be matched.\n"
        // "Known game modes: TM_Cup_Online, TM_Teams_Online, TM_Rounds_Online, TM_TimeAttack_Online, TM_Royal_Online, or TM_Campaign_Local. "
    );

    UI::Separator();

    RenderSettingsCustomGameModes();

    UI::Separator();

    UI::TextWrapped(
        "Example game modes:\n"
        "- TM_Campaign_Local\n"
        "- TM_Cup_Online\n"
        "- TM_Laps_Online\n"
        "- TM_Teams_Online\n"
        "- TM_Royal_Online\n"
        "- TM_Rounds_Online\n"
        "- TM_Champion_Online\n"
        "- TM_TimeAttack_Online\n"
        "- TM_Knockout_Online (KO Tournament)\n"
        "- TM_KnockoutDaily_Online (COTD KO rounds)\n"
        "- TM_TimeAttackDaily_Online (COTD qualifier)\n"
        "- TM_Teams_Matchmaking_Online (Ranked)\n"
    );
}

// past wizard state

[Setting hidden]
bool State_WizardShouldRun = true;

bool HasRunPastWizard() {
    // add all wizard versions here in a big AND (then NOT the result).
    return !(State_WizardShouldRun && State_WizardShouldRun_22_07_04);
}

[Setting hidden]
bool State_WizardShouldRun_22_07_04 = true;

bool GetLatestWizardShouldRun() {
    return State_WizardShouldRun_22_07_04;
}

void SetLatestWizardShouldRun(bool wsr) {
    State_WizardShouldRun_22_07_04 = wsr;
}

// general state

bool State_CurrentlyVisible = true;
bool State_UserDidUnbindWhenPrompted = false;
bool State_hasBeenInGame = false;

[SettingsTab name="Plugin State"]
void RenderSettingsPluginState() {
    State_CurrentlyVisible = UI::Checkbox("Currently visible?", State_CurrentlyVisible);
    AddSimpleTooltip("If this is false, then the prompt will be temporarily hidden for the rest of this map.");

    // State_UserDidUnbindWhenPrompted = UI::Checkbox("User did unbind when prompted", State_UserDidUnbindWhenPrompted);
    // AddSimpleTooltip("This flag is true if the user unbound giveup when prompted to.\nThis is used to figure out if the rebind prompt should be shown.");

    State_hasBeenInGame = UI::Checkbox("Has been in game?", State_hasBeenInGame);
    AddSimpleTooltip("Set to false on initial game load.");

    SetLatestWizardShouldRun(UI::Checkbox("Wizard should run?", GetLatestWizardShouldRun()));
    AddSimpleTooltip("True initially and then false forever more.");
}

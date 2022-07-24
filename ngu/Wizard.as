namespace Wizard {
    UI::Font@ font = UI::LoadFont("DroidSans.ttf", 20);

    int currWizardSlide = 0;

    void Render() {
        if (State_WizardShouldRun)
            RenderWizardUI();
    }

    void RenderWizardUI() {
        UI::PushFont(font);
        if (UI::Begin("Setup Wizard: Never Give Up", State_WizardShouldRun, GetWinFlags())) {
            UI::Dummy(vec2(150, 0));
            RenderSlide(currWizardSlide);
            UI::End();
        }
        UI::PopFont();
    }

    int GetWinFlags() {
        return 0
            | UI::WindowFlags::AlwaysAutoResize
            | UI::WindowFlags::NoCollapse
            | UI::WindowFlags::NoDocking
            ;
    }

    void RenderSlide(int slideIx) {
        switch (slideIx) {
            case 0: RenderOpeningSlide(); break;
            case 1: RenderHowItWorksSlide(); break;
            case 2: RenderDoneSlide(); break;
            default: UI::Text("unknown slide: " + slideIx);
        }
    }

    void VPad() {
        UI::Dummy(vec2(2, 10));
    }
    void Sep() {
        VPad();
        UI::Separator();
        VPad();
    }

    void RenderOpeningSlide() {
        UI::TextWrapped("Welcome to the Never Give Up Wizard!");
        VPad();
        UI::TextWrapped("A preview of the NGU prompt should appear shortly.");
        Sep();
        UI::TextWrapped("What input device do you want NGU to use?\n\\$999(You can change this in settings later.)");
        VPad();
        auto currPt = PadTypeToStr(Setting_PadType);
        if (UI::BeginCombo("Input Device", currPt, UI::ComboFlags::HeightLarge)) {
            for (uint i = 0; i < ALL_PAD_TYPES.Length; i++) {
                auto pt = ALL_PAD_TYPES[i];
                if (UI::Selectable(PadTypeToStr(pt), pt == Setting_PadType, UI::SelectableFlags::None)) {
                    Setting_PadType = pt;
                    OnSettingsChanged();
                }
            }
            UI::EndCombo();
        }
        VPad();
        UI::TextWrapped("If the preview has appeared, you should see the current bindings for your selected input device.");
        Sep();
        if (UI::Button(Icons::AngleDoubleRight + " How to Never Give Up " + Icons::AngleDoubleLeft)) {
            currWizardSlide++;
        }
    }

    void RenderHowItWorksSlide() {
        UI::TextWrapped("How does Never Give Up (NGU) work?");
        VPad();
        UI::TextWrapped("In COTD, ranked, etc, if someone accidentally hits 'Give Up' they probably wanted to respawn, instead.");
        Sep();
        UI::TextWrapped("So, NGU gives you a super quick and easy way to bind your 'Give Up' key to 'Respawn' (for those game modes) and then reminds you to rebind 'Give Up' once you're back in the menu (or in an ordinary game mode again).");
        Sep();
        UI::TextWrapped("Why don't you give it a try now?\nClick \\$3ad[ " + UnbindBtnMsg() + " ]\\$z\nOr, press \\$fd2Ctrl + Shift + " + VirtKeyToString(Setting_ShortcutKey));
        UI::TextWrapped("(Then try doing it again.)");
        Sep();
        if (UI::Button("Zoom Zoom")) {
            currWizardSlide++;
        }
    }

    void RenderDoneSlide() {
        UI::Dummy(vec2(0, 10));
        UI::Dummy(vec2(130, 0));
        UI::SameLine();
        UI::TextWrapped("\\$5e8 You're done! Gz.");
        VPad();
        UI::TextWrapped("The preview will go away when you close this window.");
        VPad();
        UI::TextWrapped("Feedback, suggestions, and requests welcome: @XertroV on the Openplanet discord.");
        VPad();
        UI::Dummy(vec2(65, 0));
        UI::SameLine();
        if (UI::Button("Never Give Up! Never Surrender!")) {
            State_WizardShouldRun = false;
        }
        UI::Dummy(vec2(0, 30));
    }
}

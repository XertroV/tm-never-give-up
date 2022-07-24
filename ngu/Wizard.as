namespace Wizard {
    UI::Font@ font = UI::LoadFont("DroidSans.ttf", 20);

    int currWizardSlide = 0;
    const int2 WindowSize = int2(440, 500);
    bool hasReboundOnce = false;
#if DEV
    string buildId = "ngu (dev)";
#else
    string buildId = "ngu";
#endif
    string uiId = buildId + "-wiz";

    void Render() {
        if (GetLatestWizardShouldRun()) {
            hasReboundOnce = (hasReboundOnce || !isGiveUpBound) && InputBindingsInitialized();
            RenderWizardUI();
        }
    }

    void RenderWizardUI() {
        UI::PushFont(font);
        const int2 pos = (int2(Draw::GetWidth(), Draw::GetHeight()) - WindowSize) / 2;
        UI::SetNextWindowPos(pos.x, pos.y, UI::Cond::Appearing);
        UI::SetNextWindowSize(WindowSize.x, WindowSize.y, UI::Cond::Always);
        if (UI::Begin("Setup Wizard: Never Give Up##" + uiId, GetWinFlags())) {
            UI::Dummy(vec2(150, 0));
            RenderSlide(currWizardSlide);
            UI::End();
        }
        UI::PopFont();
    }

    int GetWinFlags() {
        return 0
            | UI::WindowFlags::NoResize
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
        DrawCenteredInTable(uiId + "-welcome", function() {
            UI::Text("Welcome to the Never Give Up Wizard!");
        });
        if (HasRunPastWizard()) {
            DrawCenteredInTable(uiId + "-new-features", function() {
                UI::Text(rainbowLoopColorCycle("New Features!", true, -3.0));
            });
        }
        UI::TextWrapped("A preview of the NGU prompt should appear shortly.");
        Sep();
        UI::TextWrapped("What input device do you want NGU to use?\n\\$999(You can change this in settings later.)");
        VPad();
        auto currPt = PadTypeToStr(Setting_PadType);
        if (UI::BeginCombo(" Input Device", currPt, UI::ComboFlags::HeightLarge)) {
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
        UI::TextWrapped("If the preview has appeared, you should see the current bindings for your selected input device.\n(Current 'Give Up' bindings: \\$6c3" + array2str(giveUpBindings) + "\\$z)");
        VPad();
        UI::TextWrapped("\\$6afFYI:\\$z To move the prompt window, click and drag 'Never Give Up!' in the title bar.");
        Sep();
        DrawCenteredInTable(uiId + "-to-slide-2", function() {
            if (UI::Button(Icons::AngleDoubleRight + " How to Never Give Up " + Icons::AngleDoubleLeft)) {
                Wizard::currWizardSlide++;
            }
        });
    }

    void RenderHowItWorksSlide() {
        DrawCenteredInTable(uiId + "-how-ngu-works", function() {
                UI::Text("How does Never Give Up (NGU) work?");
        });
        VPad();
        UI::TextWrapped("In COTD, ranked, etc, if someone accidentally hits 'Give Up', they probably meant to respawn instead.");
        Sep();
        UI::TextWrapped("NGU gives you a super quick and easy way to bind your 'Give Up' key to 'Respawn' (during warmup for COTD, ranked, etc). Then the same thing reversed when you're back in the menu or a different game mode.");
        Sep();
        UI::TextWrapped("Why don't you give it a try now?\nClick \\$3ad[ " + UnbindBtnMsg() + " ]\\$z\nOr, press \\$fd2Ctrl + Shift + " + VirtKeyToString(Setting_ShortcutKey));
        UI::TextWrapped("(Then try doing it again.)");
        Sep();
        DrawCenteredInTable(uiId + "-to-slide-3", function() {
            if (hasReboundOnce && isGiveUpBound) {
                if (UI::Button("Zoom Zoom")) {
                    Wizard::currWizardSlide++;
                }
            } else {
                UI::BeginDisabled();
                if (hasReboundOnce)
                    UI::Button("Rebind 'Give Up' to progress");
                else
                    UI::Button("Try it out before we continue");
                UI::EndDisabled();
            }
        });
    }

    void RenderDoneSlide() {
        UI::Dummy(vec2(0, 100));
        DrawCenteredInTable(uiId + "-ur-done", function() {
            UI::Text("\\$5e8You're done! Gz.");
        });
        VPad();
        UI::TextWrapped("The preview will go away when you close this window.");
        VPad();
        UI::TextWrapped("Feedback, suggestions, and requests welcome: @XertroV on the Openplanet discord.");
        VPad();
        DrawCenteredInTable(uiId + "-finish-btn", function() {
            if (UI::Button("Never Give Up! Never Surrender!")) {
                SetLatestWizardShouldRun(false);
            }
        });
    }
}

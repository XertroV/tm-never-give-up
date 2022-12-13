# Never Give Up (Openplanet Plugin for TM2020)

This plugin will give you a convenient button and kb shortcut to rebind 'Give Up' to 'Respawn' in COTD, ranked, etc, along with a high-visibility reminder prompt that will automatically disappear when 'Give Up' is unbound.
When you return to a menu or different game mode, you'll be prompted to rebind 'Give Up' (similarly with a convenient button and a keyboard shortcut).

To experiment with the plugin, uncheck the "Hide UI in menus and for other game modes?" setting. The UI should be visible and active. (The keyboard shortcut does not work unless the plugin is visible.)

To use the buttons, the OpenPlanet overlay must be shown/visible -- otherwise buttons don't work. (The keyboard shortcut will always work when the prompt is visible, though.)

You can easily hide the prompt with one-click if you want it to go away for that session. (It will show up again the next time you're in an appropriate game mode.)

You can optionally set additional game modes to trigger the prompt.

### Feedback options

- @XertroV on [OpenPlanet Discord](https://openplanet.dev/link/discord)
- [Create GitHub Issue](https://github.com/XertroV/tm-never-give-up/issues/)

### Dialog Bug Details

**FIXED:** *v0.2.4 Adds a workaround for this issue to abort the dialog and prevent the game-breaking bug from happening! Yay! Bonus: this plugin will protect you against accidentally triggering it via the standard menu, too.*

The gist of the bug is: if you have a bind/unbind dialog open, and the game does certain things (like joining maps, or certain in-game events), then the controls lock up and the game becomes unplayable. The dialog goes away, but nearly all inputs are dropped after this point.
The only recovery method known to the author (besides restarting the game) is to open the maniascript debug console, and wait for a few minutes (maybe up to 10 min) and a 'Recovery Restart...' dialog box appears, which resets things enough to fix the issue.

### Code

GitHub Repo: [https://github.com/XertroV/tm-never-give-up](https://github.com/XertroV/tm-never-give-up)

Authors: XertroV

License: Public Domain

GL HF

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

X-Perl UnitFrames: one add-on replacing Blizzard's unit frames, for Retail 12.1 (`XPerl.toc`, interface 120100) and WoW: Forever (`XPerl_Camelot.toc`, 16001). This checkout is the fork `drpurr/xperl`. `origin` is the fork and `upstream` is `xeropresence/xperl`; the default branch is `master`. The parent `wow-addons/CLAUDE.md` rules (Forever first, wow MCP lookups, settings wording) apply.

## Checks (the same as CI, `.github/workflows/ci.yml`)

```
python3 .github/scripts/check_tocs.py          # both TOCs list the same files, every file exists with exact case
find . -name '*.lua' -not -path './.git/*' -print0 | \
  xargs -0 -I{} sh -c "sed '1s/^\xEF\xBB\xBF//' '{}' | luac5.1 -p - || echo 'FAIL {}'"   # every file compiles (BOM stripped)
luacheck .                                      # informational in CI; .luacheckrc lists the client API as read_globals
```

- There's no test suite; changes are checked in game.
- The wow MCP `wow_lua_lint` (`flavor: "forever"`) is the other static check. It flags XPerl_* globals defined in other files as unknown, so judge only the lines you changed.
- `luacheck` isn't installed locally.
- `dev-link.bat` (Windows junctions) isn't used here. The user installs the add-on by hand (folder `XPerl`), so never copy into or link to an AddOns folder.
- A TOC change needs a client restart, not `/reload`.

## Releases

Pushing a tag runs `.github/workflows/release.yml`, which builds the `.pkgmeta` zip as a GitHub release. Upstream's CurseForge webhook also packages tagged releases. Don't push tags unless asked. The version comes from the tag (`## Version: @project-version@`).

## Architecture

- **Two TOCs, one file list.** Any new file goes in both. Files listed inside XML (`XPerl_Globals.xml`, `XPerl.xml`, `Units/Units.xml`, `XPerl_Options/XPerl_FrameOptions.xml`) aren't checked by `check_tocs.py`. A `<Script>` placed at the end of an XML file runs after the frames above it exist; `XPerl_Options/XPerl_OptionDropdowns.lua` relies on this.
- **Settings.** `XPerlDB` holds one table per frame key (`player`, `target`, `party`, `raid`, ... — see `XPerl_FrameConfigKeys` in `XPerl_Globals.lua`) plus global keys at the root.
  - Modules receive it through `XPerl_RequestConfig(function(new) conf = new end)`.
  - Defaults come from the `XPerl_*_ConfigDefault` functions in `XPerl_Options/XPerl_FrameOptions.lua`. `XPerl_Options_CompleteSettings` fills in every missing default, so a new setting needs only its default there.
  - "Off" is stored as `false`. The `LEGACY_ON` lists are closed: never add new flags to them.
- **Three settings UIs, two definitions.**
  - `XPerl_EditModeSettings.lua` defines per-frame `specs.<frameKey>(s)` with a Builder (`Check`, `Slider`, `Dropdown`, `Group`, `Section`). The same lists feed the Edit Mode dialogs (LibEditMode) and the game's Settings panel (`XPerl_SettingsPanel.lua`, which registers proxy settings keyed by list index). `specs.global` is the Settings panel's main page.
  - The options window (`/xperl`) is separate XML in `XPerl_Options/XPerl_FrameOptions.xml`. Check buttons use `XPerlCheckButtonTemplate` with `configBase` / `configIndex` / `configClick`, and `Validate` + `XPerl_Options_EnableSibling` grey out dependent rows. Dropdowns added in Lua live in `XPerl_OptionDropdowns.lua`; they insert under an existing row and re-anchor whatever followed it.
  - A new option normally touches the default, the spec line, the options XML or dropdown, and the English string.
- **Applying settings.** Changes end in `XPerl_OptionActions` (`XPerl_Init.lua`), which waits until out of combat and then re-runs `XPerl_SetAllFrames`, every registered option function, text transparency and the global font (`conf.font`, applied to texts registered with `XPerl_RegisterUnitText`).
- **Unit frames.** `Units/UnitFrame.lua` is the shared framework. Each frame type (`Units/Player.lua`, `Party.lua`, ...) supplies a spec table and gets `self.conf = XPerlDB[self.frameKey]`. Portraits are all painted by `XPerl_Unit_UpdatePortrait` in `XPerl.lua`, which also draws the fork's `conf.portraitStyle` class icons from `Images/PortraitStyles/`.
- **Auras.** Buff and debuff rows are the client's `AuraContainer`s (`XPerl_Auras_*` in `XPerl.lua`).
  - Each row has groups (`mine`, `other`, `steal`, proc groups). `Auras_ApplyFilters` sets their filter strings, icon limits and `excludeSpellIDs` candidate filters. The fork's `hideTracking` is one of those exclusion sets.
  - Add-on code can't touch the icons while `C_Secrets.ShouldAurasBeSecret()` is true. Restyles (`AuraButton_Style`) are queued until then.
  - Countdown text is a `SetDurationText` binding. With MinimalistCooldownEdge installed and its Unit Frames style on, it takes MiniCE's font, curve and formatter.
- **Secret values.** In combat and in instances many unit and aura values come back secret. Guard reads with `issecretvalue` and `C_Secrets.*` and fall back to leaving the client's output alone.
- **Localization.** English lives in `localization.lua` and `XPerl_Options/localization.lua`. The other locale files are wrapped in `if (GetLocale() == "xxXX")` and override English, so English-only strings show everywhere. Several files start with a UTF-8 BOM; keep it when editing.
- **`Libs/`** holds LibStub, LibEditMode, CallbackHandler-1.0 and LibSharedMedia-3.0, all unmodified and excluded from luacheck.

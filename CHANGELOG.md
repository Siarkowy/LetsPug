# Let's Raid Changelog

## v0.5.1 (2020-10-01)

- Fixed: Lockout durations in alt overview will no longer glitch for American users.
- Fixed: Alt overview tooltip can now be entered with mouse cursor.
- Improved: Several hint texts added/adjusted for better user experience.
- New: Alt management contains a note on the limitations of synchronization.
  Additionally, a warning is shown if the current alt cannot write to public
  note while in a guild. The README file describes [synchronization limits](https://github.com/SiarkowyMods/LetsRaid#note-on-synchronization) as well.

## v0.5.0 (2020-09-17)

- Changed: Say Hi to Let's Raid! I decided to rename the addon in belief that
  a more general name fits its purpose better. Let's Raid is not only intended
  to assist in organizing pug runs, but probably even more so to ease managing
  of guild activities. And this is a big release after long time in the works!
- Improved: Time handling was overhauled for lockouts to be precise to a second.
- New: Automatic time calibration was added & enabled by default. It relies on
  available raid lockouts, and should fix previously observed time drift issues.
- New: Naxxramas & Onyxia's Lair are now supported instances for tracking.
- New: Instance focus is now core functionality of the addon, and was extended
  to a notion of raid specializations: for each talent tree, you can set its
  intended raid role (Tank/Healer/DPS) and instances of interest separately.
  This comes handy when you gear different specs of your character but they
  still aren't the same level of gear, e.g. your DPS spec is Sunwell ready but
  you still need gear from Black Temple for your healer spec to progress.
- New: Whenever you change your talent points, respective specialization
  settings will be activated. Additionally, if it's the first time you are
  seen in the given specialization, a default raid role will be assigned.
- Changed: It is now only possible to manage specialization settings for
  currently logged in character. This is in order to simplify related logic.
- New: Account & guild sync now propagates information on active specialization.
  The latter relies on being allowed to modify player notes by the guild master.
- New: It is now possible to disable writing lockout changes to player note when
  in guild. Useful when you don't want to mangle notes when sharing an account.
- New: Alt overview opens settings to active talent specialization when clicked.
- New: Also, the overview opens alt management options if no alts are shown yet.
- New: You can now find alts in the guild if it uses QDKP-compatible note system.
- Fixed: Alt overview now automatically refreshes when alts are added/hidden.
- Changed: A fresh start now defaults to a realm profile instead of account one.
- Fixed: It is now possible to properly manage profiles from within the settings.
- Changed: Settings panes were simplified and several hint texts were added.
- Improved: Several parts of code were made easily extendable to new instances.
- Changed: When writing lockouts into guild notes, instances are not grouped
  into same tier anymore. They should be more readable this way. Also, addresses
  the possibility of having different lockout durations in the same raid tier.
  However, the change is backwards compatible with existing player notes.

## v0.4.1 (2020-01-02)

- Fixed reported reset times for TBC 5-man server being 1 hour off by default.
- Fixed automatic client timezone recognition on first login. Should now properly
  account for edge cases. However, server timezone is assumed to be GMT for now;
  this functionality requires further work, possibly introducing a configurable
  timezone setting for the server.
- Fixed a bug in which short date expansion didn't honor the provided `now` date.
  This caused assertion errors in testing code; standard functionality unaffected.

## v0.4.0 (2019-09-25)

- Added RaidWatch module for easier alt tracking, with minimap button. When
  hovered, it shows a table of instance vs. character names, and each pair
  tells how much time is needed for the instance to reset, if any. Each logged
  in character will be saved to the alt list, and show up in save table. It is
  possible to add/hide/delete alts in configuration menus (/lp gui).
- Implemented instance focus for RaidWatch. Any instance can be focused by
  respective character, so that a missing raid save is shown as green "o" mark
  instead of the standard gray "x" mark. In effect, raids of higher importance
  are visible at first sight. Instance focus configuration can be opened by
  right clicking the RaidWatch minimap button or slash command (/lprw gui).
- Allowed for independent save dates in single tier (multiple T6 reset dates).
- Fixed Sunwell save recognition.

## v0.3.0 (2019-09-20)

- Increased resolution of save info handling from days to minutes. This change
  allows for better estimation of remaining instance save time as long as server
  and client timezone settings are configured.
- Save info is now stored to player's public note while in guild, and other
  players' notes are synced from too. This option is enabled by default.
- Fixed a bug where player save info would be stored without server's refresh.
- Switched to tab display in settings view (/lp gui).
- Reformatted changelog in Markdown and moved to root directory.

## v0.2.0 (2019-08-17)

- Switched to per-account profile by default, instead of per-character.
- Introduced add-on configuration interface, available through chat command (/lp)
  and GUI (/lp gui). Currently time-related server settings can be adjusted.
- Added alt management options; it is now possible to add/delete/toggle visiblity
  of player's alts. Alt functionality will be used by upcoming RaidWatch plugin.
- Client-to-server hour difference will now be infered once and reused later.
  It is possible to adjust this setting in add-on options.
- Fixed a bug where NA players' timezone offset would be off by 24 hours.
- Exposed API methods to query for player's save info and per-instance reset times.

## v0.1.0 (2019-08-11)

- First development version based on Ace3 framework.
- Implemented encoding/decoding of save info to/from short form.
- Storing logged character's name for per-profile alt listing.
- Saving player instance saves in per-realm datastore.
- Performing a regular cleanup of outdated instance saves.
- Provided instace names for enUS locale.

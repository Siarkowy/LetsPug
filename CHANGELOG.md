# Let's Raid Changelog

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

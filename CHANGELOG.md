# Let's Pug Changelog

## 0.2.0 (2019-08-17)

  - Switched to per-account profile by default, instead of per-character.
  - Introduced add-on configuration interface, available through chat command (/lp)
    and GUI (/lp gui). Currently time-related server settings can be adjusted.
  - Added alt management options; it is now possible to add/delete/toggle visiblity
    of player's alts. Alt functionality will be used by upcoming RaidWatch plugin.
  - Client-to-server hour difference will now be infered once and reused later.
    It is possible to adjust this setting in add-on options.
  - Fixed a bug where NA players' timezone offset would be off by 24 hours.
  - Exposed API methods to query for player's save info and per-instance reset times.

## 0.1.0 (2019-08-11)

  - First development version based on Ace3 framework.
  - Implemented encoding/decoding of save info to/from short form.
  - Storing logged character's name for per-profile alt listing.
  - Saving player instance saves in per-realm datastore.
  - Performing a regular cleanup of outdated instance saves.
  - Provided instace names for enUS locale.

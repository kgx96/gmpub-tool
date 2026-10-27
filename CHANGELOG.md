# Changelog

gmpub-tool by KGX (KGX PRODUCTIONS). MIT License.

## 1.0.0
First release.
- Finds Garry's Mod through Steam, including other Steam library folders; asks once if it can't.
- Settings in `gmpub-tool.ini`, Workshop IDs in `gmpub-ids.txt`, icons, notes and builds in folders next to the .bat.
- New, Update, Package and Icon, each with checks and a Y/N summary before uploading.
- Creates `addon.json` with a valid type and up to two tags.
- Lists files gmad's whitelist refuses and offers to package without them (`-warninvalid`).
- One-line change notes from `notes\<addon>.txt` or `notes\<addon>_v*.txt`; opens the full notes and the item's change notes page after an update.
- Updates several addons in a row.
- Reads the new item's ID from gmpublish's output for you to confirm.

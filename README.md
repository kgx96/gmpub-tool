# gmpub-tool

A menu for packaging and publishing **Garry's Mod addons** to the **Steam Workshop**, built on GMod's own `gmad.exe` and `gmpublish.exe`. One `.bat` file: nothing to install, works with any addon.

- Finds your Garry's Mod install through Steam (any Steam library folder)
- Lists every addon folder and remembers each one's Workshop ID
- **New**, **Update** and **Icon** uploads, with a check and a summary before anything is sent
- Creates `addon.json` for folders that don't have one (valid types and tags only)
- Shows which files gmad refuses (its whitelist) and offers to package without them
- Change notes from a text file, and the full notes ready to paste on the Workshop page
- Updates several addons in a row, in the order you pick

Windows only (gmad.exe and gmpublish.exe are Windows programs).

## Download and start

1. Download **gmpub-tool.bat** (green **Code** button > Download ZIP, or the file from the latest release) into its own folder, for example `Desktop\gmpub-tool`. Not in Program Files: the tool writes its settings and folders next to itself.
2. Start Steam and sign in to the account that owns (or will own) the Workshop items.
3. Double-click `gmpub-tool.bat`.

On the first start it looks for Garry's Mod through Steam. If it can't find it, drag your `GarrysMod` folder into the window when it asks (for example `C:\Program Files (x86)\Steam\steamapps\common\GarrysMod`).

It then makes these next to the .bat:

| File / folder | What it is |
|---|---|
| `gmpub-tool.ini` | Your settings (Garry's Mod, addons, icons and notes folders) |
| `gmpub-ids.txt` | Saved Workshop IDs, one per line: `folder_name=ID` |
| `icons\` | Workshop icons: `<addon folder name>.jpg` |
| `notes\` | Change notes: `<addon folder name>.txt` or `<addon folder name>_v<version>.txt` |
| `build\` | The `.gma` files it packages |

## The menus

**Main menu**

| Key | Does |
|---|---|
| 1 | List your published Workshop items (`gmpublish list`) |
| 2 | Show the addon folders and select one (by number or folder name). A folder without `addon.json` can get one right away |
| 3 | Actions for the selected addon (below) |
| 4 | Update several addons in a row: type the numbers in order, e.g. `3 1 7`. Each one asks Y (upload), S (skip) or Q (stop); saved IDs are updated, the others published as new |
| 5 | Open the addons folder |
| S | Settings: folders, find Garry's Mod again, edit the saved IDs |
| H | Help |

**Actions for the selected addon**

| Key | Does |
|---|---|
| A | **New**: icon, check, package, summary, then publish as a new Workshop item. The new ID is read from gmpublish's output for you to confirm and is saved |
| B | **Package** only: check and build `build\<addon>.gma` |
| C | **Update**: check, package, change notes, summary, then update the item with the saved ID |
| D | Set or change the saved Workshop ID |
| E | Open the addon folder |
| F | **Icon**: upload a new thumbnail for the existing item (the addon files are not uploaded) |
| G | Open the item's Workshop page and its change notes |
| J | Create or replace `addon.json` (the old one is kept as `addon.json.bak`) |

Nothing is uploaded without a **Y** at the summary.

## Checks before packaging

- `addon.json` exists and has a `"title"` and a `"type"`.
- gmad's full output is shown. If gmad refuses files because they are not on its [whitelist](https://wiki.facepunch.com/gmod/Workshop_Addon_Creation), they are listed on their own. Move them out of the folder, add them to `"ignore"` in `addon.json`, or answer **Y** to package without them (gmad's `-warninvalid`).
- The `.gma` size is shown before any upload.

## Icons

Put `<addon folder name>.jpg` in the `icons` folder, for example `icons\my_addon.jpg`. Steam wants a **JPG**, **512 x 512** is the usual size, and it must be **under 1 MB**. You can also drag any JPG into the window when it asks.

Keep icons out of the addon folder itself: gmad refuses image files there (except under `materials\`).

## Change notes

gmpublish uploads **one line** of change notes. The tool builds it from your notes file, `notes\<addon>.txt` (or the newest `notes\<addon>_v*.txt`, e.g. `my_addon_v1.4.0.txt`): its first two lines without BBCode. Keep notes files in plain ASCII (no curly quotes or accented letters): the console reads them in its own code page. For example a file starting with

```
[h2]v1.4.0[/h2]
[b]Faster spawning[/b]
[list]
...
```

gives `v1.4.0: Faster spawning`. Press **Enter** to use it or type your own. No notes file: `Updated addon.`

After an update it can open the full notes file in Notepad and the item's change notes page: copy everything, click **Edit** on the newest entry, paste.

## addon.json

Option **J** (or selecting a folder without one) writes:

```json
{
	"title": "My Addon",
	"type": "tool",
	"tags": ["fun", "build"],
	"ignore": ["*.psd", "*.vcproj", "*.svn*", ".git*", "*.md", "*.bak"]
}
```

You pick the type from gmad's list (gamemode, map, weapon, vehicle, npc, entity, tool, effects, model, servercontent) and up to two tags (fun, roleplay, scenic, movie, realism, cartoon, water, comic, build). See [examples/addon.json](examples/addon.json).

## Settings file

`gmpub-tool.ini` is plain text; change it in **Settings** or by hand:

```ini
GMODDIR=D:\SteamLibrary\steamapps\common\GarrysMod
ADDONS=D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons
ICONDIR=C:\Users\you\Desktop\gmpub-tool\icons
NOTESDIR=C:\Users\you\Desktop\gmpub-tool\notes
```

`ADDONS` can be any folder of addon folders, not only GMod's `addons` folder.

Already have a list of IDs? Put them in `gmpub-ids.txt` as `folder_name=ID`, one per line (lines starting with `#` are ignored).

## Troubleshooting

| Problem | Fix |
|---|---|
| "Steam is not running" | Start Steam and sign in, then try again. gmpublish talks to the running Steam client |
| Garry's Mod not found | Settings > 1 and drag the `GarrysMod` folder in. The folder must contain `bin\gmad.exe` and `bin\gmpublish.exe` |
| Package failed | Read gmad's message above the error. Most often: a file not on the whitelist, or a bad `addon.json` (type or tags not in the lists above) |
| Upload failed | Steam signed in to a different account than the item's owner, the item ID is wrong, or the icon is not a JPG under 1 MB |
| Text looks broken / a path with `!`, `%` or `^` in it | Paths and folder names containing `!`, `%` or `^` are not supported (a limit of Windows batch files). Rename the folder |
| "Access is denied" when it starts | The tool is in a protected folder such as Program Files. Move it to your Desktop or Documents |
| gmpublish "ended with error code" | Read gmpublish's output above it. Steam not running, a different Steam account, or a wrong item ID are the usual causes |

## Manual commands

What the tool runs, if you want to do it yourself in a Command Prompt (paths are examples):

```bat
cd /d "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\bin"
gmad.exe create -folder "..\garrysmod\addons\my_addon" -out "C:\gmpub-tool\build\my_addon.gma"
gmpublish.exe create -addon "C:\gmpub-tool\build\my_addon.gma" -icon "C:\gmpub-tool\icons\my_addon.jpg"
gmpublish.exe update -addon "C:\gmpub-tool\build\my_addon.gma" -id "1234567890" -changes "Fixed spawning"
gmpublish.exe update -icon "C:\gmpub-tool\icons\my_addon.jpg" -id "1234567890"
gmpublish.exe list
```

## Contributing

Bug reports and ideas: open an [issue](../../issues). Pull requests are welcome; please keep the tool a single `.bat` with no extra installs, and keep it **ASCII with CRLF line endings** (`.gitattributes` handles that in Git).

## License

[MIT](LICENSE). Copyright (c) 2026 KGX PRODUCTIONS.

Not affiliated with Facepunch Studios or Valve. Garry's Mod, Steam and the Steam Workshop are trademarks of their owners; gmad.exe and gmpublish.exe ship with Garry's Mod.

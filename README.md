<p align="center">
  <img src="https://raw.githubusercontent.com/edintomato2/Beret/master/Assets/logo.png" width="500"/>
  <br>(logo by zeko)
</p>

### Beret, a level editor and viewer for FEZ.
---
Level viewing and editing
---
1. Use [FEZRepacker](https://github.com/FEZModding/FEZRepacker) to extract the contents of your FEZ `.pak` files. Note that most of the good stuff is stored in `Other.pak`!
2. Launch Beret.exe. You'll have to tell Beret where your decompiled directories are by going to `File > Asset Dirs...`!
3. Load a `.fezlvl.json` file from the File menu! (`.fezlvl.json`s are usually found in the `Others/levels` directory!)
4. Alternatively, you can make a new level from scratch by pressing the "New Level" button instead. This will ask you to load a specific trileset for your level!

Level testing
---
Thanks to HAT v1.1.0, levels don't have to be recompiled into a `.pak` file!

1. [Follow this guide to create an asset mod for FEZ.](https://github.com/FEZModding/HAT/blob/main/Docs/createmods.md)
2. Place your levels into `Assets/levels/`.
3. Install [FEZUG](https://github.com/FEZModding/FEZUG) if you haven't already!
4. Run `MONOMODDED_FEZ.exe`, and press ` to open FEZUG's console.
5. Warp to your level with `warp <level_name>`!

Usage
---
|Key(s)|What they do|
|:---:|:---:|
| Mouse | Move the cursor around |
| Middle Mouse Button | Rotate around 
| Shift + Middle Mouse Button | Pan around |
| Q/E | Rotate by 90 degrees|
| Left Alt | Snap to closest 2D view | 
| Numpad 5 | Perspective to Ortho mode switch |
| X | Delete object |
| Left Click | Place object |
| Arrow Keys | Select from palette |


Screenshots
---
> [!WARNING]
> Since I'm updating this pretty often, screenshots may not necessarily be representative of the latest release!

Regardless, here are a few screenshots.
![Screenshot of level "OWL"](https://github.com/edinosma/Beret/blob/master/github/beret_screenshot.png?raw=true)
![Screenshot of custom level "BERET"](https://github.com/edintomato2/Beret/blob/master/github/beret_logo_wall.png?raw=true)

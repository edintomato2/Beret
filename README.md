<p align="center">
  <img src="https://github.com/edinosma/Beret/blob/master/beret_logo.png?raw=true" />
</p>

### Beret, a level editor and viewer for FEZ.
---
Level viewing and editing
---
1. Use [FEZRepacker](https://github.com/FEZModding/FEZRepacker) to extract the contents of your FEZ `.pak` files. Note that most of the good stuff is stored in `Other.pak`!
2. Launch Beret.exe. Go through the first time setup to tell Beret where your decompiled directories are.
3. Load a `.fezlvl.json` file from the File menu! (`.fezlvl.json`s are usually found in the levels directory)
4. Alternatively, you can make a new level from scratch by pressing the "New Level" button instead. This will ask you to load a specific trileset for your level!

> [!WARNING]
> Trilesets with more than 256 triles ("Untitled", "Random") currently don't load correctly!

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
|Key(s)|What it does|
|:---:|:---:|
|W/S|Up/Down|
|A/D|Left/Right|
|R/F|Forwards/Backwards|
|X|Delete object (trile, art object, NPC...)|
|Left Click|Place object|
|Arrow Keys|Select from palette|

Screenshots
---
> [!WARNING]
> Since I'm updating this pretty often, screenshots may not necessarily be representative of the latest release!

Regardless, here are a few screenshots.
![Screenshot of level "OWL"](https://github.com/edinosma/Beret/blob/master/github/beret_screenshot.png?raw=true)
![Screenshot of custom level "BERET"](https://github.com/edintomato2/Beret/blob/master/github/beret_logo_wall.png?raw=true)

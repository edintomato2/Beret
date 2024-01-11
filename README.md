<p align="center">
  <img src="https://github.com/edinosma/Beret/blob/master/beret_logo.png?raw=true" />
</p>

### Beret, a level editor and viewer for FEZ.
---
#### Level viewing and editing:
1. Use [FEZRepacker](https://github.com/FEZModding/FEZRepacker) to extract the contents of your FEZ `.pak` files. Note that most of the good stuff is stored in `Other.pak`!
2. Launch Godot, and run MainScene.tscn.
3. Load a `.fezlvl.json` file from the File menu! (`.fezlvl.json`s are usually found in the levels directory)

#### Level testing:
1. Move your level files into their own separate root folder (something like `Beret/levels/`)
1. Use [FEZRepacker](https://github.com/FEZModding/FEZRepacker) to add your levels to your `Other.pak` file. The command should look something like `FEZRepacker.exe --pack "Beret" Other_new.pak Other.pak`
2. Replace the `Other.pak` file in FEZ's `Content` directory with the new `.pak` file. Be sure that FEZ has [HAT](https://github.com/FEZModding/HAT) and [FEZUG](https://github.com/FEZModding/FEZUG) installed!
3. Open the FEZUG console and warp to your level with `warp <level_name>`!
---
### Screenshots
![Screenshot of level "OWL"](https://github.com/edinosma/Beret/blob/master/github/beret_screenshot.png?raw=true)

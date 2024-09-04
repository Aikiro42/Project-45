set version=%1
cd ../../../../win32/
asset_packer.exe "../mods/Project 45" "../mods/Project 45/docs/devtools/packed/%version%.pak"
cd "../mods/Project 45/docs/devtools"
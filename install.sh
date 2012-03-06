#!/bin/sh
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Name=mycard
Name[zh_CN]=萌卡
Comment=a card game
Comment[zh_CN]=卡片游戏对战客户端
Exec=ruby lib/main.rb
Terminal=false
Icon=$(dirname "$0")/graphics/system/icon.gif
Type=Application
Categories=Game
Path=$(dirname "$0")" > ~/.local/share/applications/mycard.desktop

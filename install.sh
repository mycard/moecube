#!/bin/sh
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Mycard
Name[zh_CN]=Mycard - 萌卡
Comment=a card game platform
Comment[zh_CN]=卡片游戏对战客户端
Exec=/usr/bin/env ruby -KU lib/main.rb %u
Terminal=false
Icon=$(dirname "$0")/graphics/system/icon.png
Type=Application
Categories=Game
Path=$(dirname "$0")
URL=http://my-card.in/
MimeType=x-scheme-handler/mycard;application/x-ygopro-deck;application/x-ygopro-replay" > ~/.local/share/applications/mycard.desktop

echo "<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-ygopro-deck">
		<comment>ygopro deck</comment>
		<icon name="application-x-ygopro-deck"/>
		<glob-deleteall/>
		<glob pattern="*.ydk"/>
	</mime-type>
</mime-info>" > ~/.local/share/mime/packages/application-x-ygopro-deck.xml 

echo "<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        <mime-type type="application/x-ygopro-replay">
                <comment>ygopro replay</comment>
                <icon name="application-x-ygopro-replay"/>
                <glob-deleteall/>
                <glob pattern="*.yrp"/>
        </mime-type>
</mime-info>" > ~/.local/share/mime/packages/application-x-ygopro-replay.xml 

xdg-mime default mycard.desktop application/x-ygopro-deck
xdg-mime default mycard.desktop application/x-ygopro-replay
xdg-mime default mycard.desktop x-scheme-handler/mycard

update-mime-database ~/.local/share/mime
update-desktop-database

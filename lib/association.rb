module Association
  module_function

  def register
    if Windows
      require 'win32/registry'
      path, command, icon = paths
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard') { |reg| reg['URL Protocol'] = path.ljust path.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\shell\open\command') { |reg| reg[nil] = command.ljust command.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\DefaultIcon') { |reg| reg[nil] = icon.ljust icon.bytesize }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.ydk') { |reg| reg[nil] = 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.yrp') { |reg| reg[nil] = 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.deck') { |reg| reg[nil] = 'mycard' }
    else
      require 'fileutils'
      FileUtils.mkdir_p("#{ENV['HOME']}/.local/share/applications") unless File.directory?("#{ENV['HOME']}/.local/share/applications")
      open("#{ENV['HOME']}/.local/share/applications/mycard.desktop", 'w') { |f| f.write <<EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Mycard
Name[zh_CN]=Mycard - 萌卡
Comment=a card game platform
Comment[zh_CN]=卡片游戏对战客户端
Exec=/usr/bin/env ruby -KU lib/main.rb %u
Terminal=false
Icon=#{Dir.pwd}/graphics/system/icon.png
Type=Application
Categories=Game
Path=#{Dir.pwd}
URL=http://my-card.in/
MimeType=x-scheme-handler/mycard;application/x-ygopro-deck;application/x-ygopro-replay'
EOF
      }
      FileUtils.mkdir_p("#{ENV['HOME']}/.local/share/mime/packages") unless File.directory?("#{ENV['HOME']}/.local/share/mime/packages")
      open("#{ENV['HOME']}/.local/share/mime/packages/application-x-ygopro-deck.xml", 'w') { |f| f.write <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-ygopro-deck">
		<comment>ygopro deck</comment>
		<icon name="application-x-ygopro-deck"/>
		<glob-deleteall/>
		<glob pattern="*.ydk"/>
	</mime-type>
</mime-info>
EOF
      }
      open("#{ENV['HOME']}/.local/share/mime/packages/application-x-ygopro-replay.xml", 'w') { |f| f.write <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        <mime-type type="application/x-ygopro-replay">
                <comment>ygopro replay</comment>
                <icon name="application-x-ygopro-replay"/>
                <glob-deleteall/>
                <glob pattern="*.yrp"/>
        </mime-type>
</mime-info>
EOF
      }
      system("install -D #{Dir.pwd}/graphics/system/icon.png ~/.icons/application-x-ygopro-deck.png")
      system("install -D #{Dir.pwd}/graphics/system/icon.png ~/.icons/application-x-ygopro-replay.png")
      system("xdg-mime default mycard.desktop application/x-ygopro-deck application/x-ygopro-replay x-scheme-handler/mycard")
      system("update-mime-database #{ENV['HOME']}/.local/share/mime")
      system("update-desktop-database #{ENV['HOME']}/.local/share/applications")
    end
  end

  def paths
    pwd = Dir.pwd.gsub('/', '\\')
    path = '"' + pwd + '\ruby\bin\rubyw.exe" -C"' + pwd + '" -KU lib/main.rb'
    command = path + ' "%1"'
    icon = '"' + pwd + '\mycard.exe", 0'
    [path, command, icon]
  end

  def need?
    return false if $config['no_assoc']
    if Windows
      path, command, icon = paths
      require 'win32/registry'
      begin
        Win32::Registry::HKEY_CLASSES_ROOT.open('mycard') { |reg| return true unless reg['URL Protocol'] == path }
        Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\shell\open\command') { |reg| return true unless reg[nil] == command }
        Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\DefaultIcon') { |reg| return true unless reg[nil] == icon }
        Win32::Registry::HKEY_CLASSES_ROOT.open('.ydk') { |reg| return true unless reg[nil] == 'mycard' }
        Win32::Registry::HKEY_CLASSES_ROOT.open('.yrp') { |reg| return true unless reg[nil] == 'mycard' }
        Win32::Registry::HKEY_CLASSES_ROOT.open('.deck') { |reg| return true unless reg[nil] == 'mycard' }
      rescue
        return true
      end
    else
      true #how to detect?
    end
  end

  def request
    require_relative 'widget_msgbox'
    Widget_Msgbox.new("mycard", "即将进行文件关联, 弹出安全警告请点允许", ok: "确定", cancel: "取消") do |clicked|
      if clicked == :ok
        yield
      else
        Widget_Msgbox.new("mycard", "未进行关联,要重新关联请删除config.yml", ok: "确定")
        $config['no_assoc'] = true
        Config.save
      end
    end
  end

  def start
    if need?
      if Windows
        request do
          require 'rbconfig'
          register rescue Dialog.uac(File.join(RbConfig::CONFIG["bindir"],RbConfig::CONFIG["RUBY_INSTALL_NAME"] + RbConfig::CONFIG["EXEEXT"]), "-KU lib/main.rb register_association")
        end
      else
        register
      end
    end
  end

end
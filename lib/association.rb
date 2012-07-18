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
    return false unless Windows
    return false if $config['no_assoc']
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
      request do
       register rescue Dialog.uac("ruby/bin/rubyw.exe", "-KU lib/main.rb register_association")
      end
    end
  end
end
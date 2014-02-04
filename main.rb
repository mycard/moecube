#encoding: UTF-8
# = Building
if defined?(Ocra) or defined?(Exerb)
  #stdlib
  require 'json'
  require 'pathname'
  require 'fileutils'
  require 'uri'
  require 'open-uri'
  require 'win32api'
  require 'fiddle'
  require 'win32ole'
  require 'win32/registry'
  require 'socket'
  require 'digest/md5'

  #gems
  require 'websocket-eventmachine-server'
  require 'em-http'
  require 'rb-notifu'
  require 'sqlite3'
  require 'data-uri'

  #open-uri protocol
  require 'net/http'

  #websocket autoload
  WebSocket::Frame::Base
  WebSocket::Frame::Data
  WebSocket::Frame::Handler::Base
  WebSocket::Frame::Handler::Handler03
  WebSocket::Frame::Handler::Handler04
  WebSocket::Frame::Handler::Handler05
  WebSocket::Frame::Handler::Handler07
  WebSocket::Frame::Handler::Handler75
  WebSocket::Frame::Incoming::Client
  WebSocket::Frame::Incoming::Server
  WebSocket::Frame::Outgoing::Client
  WebSocket::Frame::Outgoing::Server
  WebSocket::Handshake::Base
  WebSocket::Handshake::Client
  WebSocket::Handshake::Handler::Base
  WebSocket::Handshake::Handler::Client
  WebSocket::Handshake::Handler::Client01
  WebSocket::Handshake::Handler::Client04
  WebSocket::Handshake::Handler::Client75
  WebSocket::Handshake::Handler::Client76
  WebSocket::Handshake::Handler::Server
  WebSocket::Handshake::Handler::Server04
  WebSocket::Handshake::Handler::Server75
  WebSocket::Handshake::Handler::Server76
  WebSocket::Handshake::Server


  exit
end
# = Runtime
begin
  # == initialize

  Version = "2.0.0"
  Platform = (RUBY_PLATFORM['mswin'] || RUBY_PLATFORM['mingw']) ? :win32 : :linux
  System_Encoding = Encoding.find("locale") rescue Encoding.find(Encoding.locale_charmap)
  pwd = File.dirname(defined?(ExerbRuntime) ? ExerbRuntime.filepath.dup.force_encoding(System_Encoding).encode!(Encoding::UTF_8) : ENV["OCRA_EXECUTABLE"] || __FILE__)
  Dir.chdir pwd
  # == config

  Config = {
      'port' => 9998,
      'ygopro' => {
          'path' => ['ygocore/ygopro_vs.exe', 'ygopro_vs.exe', 'ygocore/ygopro', 'ygopro', 'ygocore/gframe', 'gframe'],
          'textfont' => ['fonts/wqy-microhei.ttc', '/usr/share/fonts/wqy-microhei/wqy-microhei.ttc', '/usr/share/fonts/truetype/wqy/wqy-microhei.ttc', '/Library/Fonts/Hiragino Sans GB W3.otf', 'c:/windows/fonts/simsun.ttc'],
          'numfont' => ['/usr/share/fonts/gnu-free/FreeSansBold.ttf', 'c:/windows/fonts/arialbd.ttf']
      },
      "url" => 'http://my-card.in/rooms'
  }
  require 'json'
  if File.file? 'config.json'
    config = open('config.json') { |f| JSON.load(f) }
    Config.merge! config if config.is_a? Hash
  end

  Config['ygopro']['path'] = Config['ygopro']['path'].find { |path| File.file? path } if Config['ygopro']['path'].is_a? Enumerable
  Config['ygopro']['textfont'] = Config['ygopro']['textfont'].find { |path| File.file? path } if Config['ygopro']['textfont'].is_a? Enumerable
  Config['ygopro']['numfont'] = Config['ygopro']['numfont'].find { |path| File.file? path } if Config['ygopro']['numfont'].is_a? Enumerable


  if !Config['ygopro']['path'] or !File.file? Config['ygopro']['path']
    require 'win32api'
    GetOpenFileName = Win32API.new("comdlg32.dll", "GetOpenFileNameW", "p", "i")


    title = "select ygopro_vs.exe"
    filter = {"ygopro_vs.exe" => "ygopro_vs.exe"}

    OFN_EXPLORER = 0x00080000
    OFN_PATHMUSTEXIST = 0x00000800
    OFN_FILEMUSTEXIST = 0x00001000
    OFN_ALLOWMULTISELECT = 0x00000200
    OFN_FLAGS = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST |
        OFN_ALLOWMULTISELECT
    szFile = (0.chr * 20481).encode("UTF-16LE")
    szFileTitle = 0.chr * 2049
    szTitle = (title+"\0").encode("UTF-16LE")
    szFilter = (filter.flatten.join("\0")+"\0\0").encode("UTF-16LE")
    szInitialDir = "\0"

    ofn =
        [
            76, # lStructSize       L
            0, # hwndOwner         L
            0, # hInstance         L
            szFilter, # lpstrFilter       L
            0, # lpstrCustomFilter L
            0, # nMaxCustFilter    L
            1, # nFilterIndex      L
            szFile, # lpstrFile         L
            szFile.size - 1, # nMaxFile          L
            szFileTitle, # lpstrFileTitle    L
            szFileTitle.size - 1, # nMaxFileTitle     L
            szInitialDir, # lpstrInitialDir   L
            szTitle, # lpstrTitle        L
            OFN_FLAGS, # Flags             L
            0, # nFileOffset       S
            0, # nFileExtension    S
            0, # lpstrDefExt       L
            0, # lCustData         L
            0, # lpfnHook          L
            0 # lpTemplateName    L
        ].pack("LLLPLLLPLPLPPLS2L4")

    GetOpenFileName.call(ofn)
    Dir.chdir pwd

    result = szFile.delete("\0".encode(Encoding::UTF_16LE)).encode(Encoding::UTF_8)
    if !result.empty? and File.file? result
      require 'pathname'
      result = Pathname.new(result).cleanpath.to_s.gsub('\\', '/')
      Config['ygopro']['path'] = result
    else
      exit
    end
  else
    require 'pathname'
    Config['ygopro']['path'] = Pathname.new(Config['ygopro']['path']).cleanpath.to_s.gsub('\\', '/')
  end

  def save_config(config=Config)
    require 'json'
    open('config.json', 'w') { |f| JSON.dump config, f }
  end

  def registed?
    path, command, icon = register_paths
    require 'win32/registry'
    begin
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard') { |reg| return false unless reg['URL Protocol'] == path }
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\shell\open\command') { |reg| return false unless reg[nil] == command }
      Win32::Registry::HKEY_CLASSES_ROOT.open('mycard\DefaultIcon') { |reg| return false unless reg[nil] == icon }
      Win32::Registry::HKEY_CLASSES_ROOT.open('.ydk') { |reg| return false unless reg[nil] == 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.open('.yrp') { |reg| return false unless reg[nil] == 'mycard' }
        #Win32::Registry::HKEY_CLASSES_ROOT.open('.deck') { |reg| return false unless reg[nil] == 'mycard' }
    rescue
      return false
    end
    true
  end

  def register_paths
    path = defined?(ExerbRuntime) ? ExerbRuntime.filepath : ENV["OCRA_EXECUTABLE"] || File.expand_path($0).gsub('/', '\\')
    command = "\"#{path}\" \"%1\""
    icon = "\"#{path}\" ,0"
    [path, command, icon]
  end

  def register
    require 'win32/registry'
    path, command, icon = register_paths
    begin
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard') { |reg| reg['URL Protocol'] = path }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\shell\open\command') { |reg| reg[nil] = command }
      Win32::Registry::HKEY_CLASSES_ROOT.create('mycard\DefaultIcon') { |reg| reg[nil] = icon }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.ydk') { |reg| reg[nil] = 'mycard' }
      Win32::Registry::HKEY_CLASSES_ROOT.create('.yrp') { |reg| reg[nil] = 'mycard' }
      #Win32::Registry::HKEY_CLASSES_ROOT.create('.deck') { |reg| reg[nil] = 'mycard' }
      true
    rescue Win32::Registry::Error #Access Denied, need elevation
      if defined?(ExerbRuntime)
        System.elevate ExerbRuntime.filepath, ['register']
      elsif ENV["OCRA_EXECUTABLE"]
        System.elevate ENV["OCRA_EXECUTABLE"], ['register']
      else
        System.elevate Gem.ruby, [$0, 'register']
      end
      'elevated'
    end
  end


  def service
    require 'socket'
    begin
      TCPServer.new('0.0.0.0', Config['port']).close
    rescue Errno::EADDRINUSE
      return #check port in use, seems eventmachine enabled IP_REUSEADDR.
    end
    require 'websocket-eventmachine-server'
    EventMachine.run do
      ygopro_version = nil
      connections = []

      EventMachine.error_handler { |exception|
        error = "程序出现了错误，请把你的操作及以下信息发送至zh99998@gmail.com来帮助我们完善程序
an error occurs, please send your operation and message below to zh99998@gmail.com

#{exception.inspect.encode(Encoding::UTF_8)}
        #{exception.backtrace.join("\n").encode(Encoding::UTF_8)}"
        open('error.txt', 'w:utf-8') { |f| f.write error }
        spawn 'notepad', 'error.txt'
      }

      WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => Config['port']) do |ws|
        ws.onopen do
          connections.push ws
          msg = {'version' => Version}
          msg['ygopro_version'] = ygopro_version if ygopro_version
          ws.send(msg.to_json)
        end

        ws.onmessage do |msg, type|
          ws.send parse(msg.encode!(Encoding::UTF_8)).to_json
        end

        ws.onclose do
          connections.delete ws
          exit if connections.empty?
        end
      end

      require 'em-http'
      http = EM::HttpRequest.new('https://my-card.in/ygopro_version.json').get
      http.callback { |http|
        md5 = Digest::MD5.file(Config['ygopro']['path']).hexdigest
        ygopro_version = JSON.parse(http.response)[md5] || md5
        connections.each { |ws| ws.send ({'ygopro_version' => ygopro_version}).to_json }
      }
      if File.file? File.join(File.dirname(Config['ygopro']['path']), 'cards.cdb')
        require 'sqlite3'
        db = SQLite3::Database.new File.join(File.dirname(Config['ygopro']['path']), 'cards.cdb')
        cards = db.execute('select id from datas').flatten
        images_to_download = cards - Dir.glob(File.join(File.dirname(Config['ygopro']['path']), 'pics', '*.jpg')).collect { |file| File.basename(file, '.jpg').to_i }
        thumbnails_to_download = cards - Dir.glob(File.join(File.dirname(Config['ygopro']['path']), 'pics', 'thumbnail', '*.jpg')).collect { |file| File.basename(file, '.jpg').to_i }
      end
      unless images_to_download.empty? and thumbnails_to_download.empty?
        require 'uri'
        http = EM::HttpRequest.new('https://my-card.in/cards/image.json').get
        http.callback {
          response = JSON.parse http.response
          image_url = URI(response['url'])
          thumbnail_url = URI(response['thumbnail_url'])
          Dir.mkdir File.join(File.dirname(Config['ygopro']['path']), 'pics') unless File.directory? File.join(File.dirname(Config['ygopro']['path']), 'pics')
          Dir.mkdir File.join(File.dirname(Config['ygopro']['path']), 'pics', 'thumbnail') unless File.directory? File.join(File.dirname(Config['ygopro']['path']), 'pics', 'thumbnail')
          files = {}
          thumbnails_to_download.each { |card_id| files[thumbnail_url.path.gsub(':id', card_id.to_s)] = File.join(File.dirname(Config['ygopro']['path']), 'pics', 'thumbnail', card_id.to_s + '.jpg') }
          images_to_download.each { |card_id| files[image_url.path.gsub(':id', card_id.to_s)] = File.join(File.dirname(Config['ygopro']['path']), 'pics', card_id.to_s + '.jpg') }
          thumbnails_count = thumbnails_to_download.size
          images_count = images_to_download.size
          errors_count = 0
          puts files.keys.join("\n")
          batch_download(image_url.to_s, files, 'image/jpeg') { |http|
            if http.req.path["thumbnail"]
              thumbnails_count -= 1
            else
              images_count -= 1
            end
            unless http.response_header.status == 200 and http.response_header['CONTENT_TYPE'] == 'image/jpeg'
              errors_count += 1
            end
            connections.each { |ws| ws.send ({'images_download_images' => images_count, 'images_download_thumbnails' => thumbnails_count, 'images_download_errors' => errors_count}).to_json }
          }
        }
        require 'rb-notifu'
        Notifu::show :message => "缩略: #{thumbnails_to_download.size}, 完整: #{images_to_download.size}".encode(System_Encoding), :baloon => false, :type => :info, :title => "正在下载卡图".encode(System_Encoding) do |status|
          if status == 3
            System.web 'http://my-card.in/rooms/'
          end
        end
      end
    end
  end

  def batch_download(main_url, files, content_type=nil, &block)
    connections = {}
    count = {total: files.size, error: 0}
    [10*100, files.size].min.times { do_download(main_url, files, content_type, count, connections, &block) }
  end

  def do_download(main_url, files, content_type, count, connections, &block)
    if connections.size < 10
      connection = EventMachine::HttpRequest.new(main_url)
      connections[connection] = 0
    else
      connection = connections.min_by { |key, value| value }
      if connection[1] >= 100
        return
      else
        connection = connection[0]
      end
    end
    remote_path, local_path = files.shift
    connections[connection] += 1
    connection.get(path: remote_path, keepalive: connections[connection] != 100).callback { |http|
      #puts File.basename local_path
      count[:error] = 0
      count[:total] -= 1
      if http.response_header['CONNECTION'] != 'keep-alive'
        connection.close
        connections.delete(connection)
        do_download(main_url, files, content_type, count, connections, &block) while !files.empty? and (connections.size < 10 or connections.values.min < 100)
      end

      if http.response_header.status == 200 and (!content_type or http.response_header['CONTENT_TYPE'] == content_type)
        IO.binwrite local_path, http.response
      else
        puts http.response_header.http_status
      end

      yield http

      if count[:total].zero?
        connections.each_key { |connection| connection.close }
        connections.clear
      end

    }.errback { |http|
      puts http.error
      connection.close
      connections.delete(connection)
      files[remote_path] = local_path
      count[:error] += 1
      if count[:error] <= 10*100
        do_download(main_url, files, content_type, count, connections, &block) while !files.empty? and (connections.size < 10 or connections.values.min < 100)
      else
        connections.each_key { |connection| connection.close }
        connections.clear
        puts 'network error'
      end
    }
  end


  def load_system_conf
    system_conf = {}
    conf_path = File.join(File.dirname(Config['ygopro']['path']), 'system.conf')
    IO.readlines(conf_path, encoding: Encoding::UTF_8).each do |line|
      next if line[0, 1] == '#'
      field, contents = line.chomp.split(' = ', 2)
      system_conf[field] = contents
    end if File.file? conf_path
    system_conf
  end

  def save_system_conf(system_conf)
    font, size = system_conf['textfont'] ? system_conf['textfont'].split(' ') : nil
    if Config['ygopro']['textfont'] and (!font or !File.file?(File.expand_path(font, File.dirname(Config['ygopro']['path']))) or size.to_i.to_s != size)
      require 'pathname'
      font_path = Pathname.new(Config['ygopro']['textfont'])
      font_path = font_path.relative_path_from(Pathname.new(File.dirname(Config['ygopro']['path']))) if font_path.relative?
      system_conf['textfont'] = "#{font_path} 14"
    end

    font = system_conf['numfont']
    if Config['ygopro']['numfont'] and (!font or !File.file?(File.expand_path(font, File.dirname(Config['ygopro']['path']))))
      require 'pathname'
      font_path = Pathname.new(Config['ygopro']['numfont'])
      font_path = font_path.relative_path_from(Pathname.new(File.dirname(Config['ygopro']['path']))) if font_path.relative?
      system_conf['numfont'] = font_path
    end
    open(File.join(File.dirname(Config['ygopro']['path']), 'system.conf'), 'w:UTF-8') { |file| file.write system_conf.collect { |key, value| "#{key} = #{value}" }.join("\n") }
  end

  module System
    BUTTONS_OK = 0

    def message_box(txt, title=nil, buttons=BUTTONS_OK)
      require 'dl'
      user32 = DL.dlopen('user32')
      msgbox = user32['MessageBoxA', 'ILSSI']
      r, rs = msgbox.call(0, txt, title, buttons)
      return r
    end

    module_function

    def web(path=Config['url'], *args)
      require 'win32ole'
      $shell ||= WIN32OLE.new('Shell.Application')
      $shell.ShellExecute(path, *args)
    end

    def elevate(path, args, pwd = Dir.pwd)
      web path, args.collect { |arg| arg.inspect }.join(' '), Dir.pwd, 'runas'
    end
  end

  def run_ygopro(parameter)
    spawn File.basename(Config['ygopro']['path']), *parameter, chdir: File.dirname(Config['ygopro']['path']).encode(System_Encoding)
    require 'fiddle'
    user32 = Fiddle.dlopen('user32')
    findWindow = Fiddle::Function.new(
        user32['FindWindow'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_INT
    )
    setForegroundWindow = Fiddle::Function.new(
        user32['SetForegroundWindow'],
        [Fiddle::TYPE_INT],
        Fiddle::TYPE_CHAR
    )
    100.times do
      if (hwnd = findWindow.call('CIrrDeviceWin32', nil)) != 0
        setForegroundWindow.call(hwnd)
        break
      else
        sleep 0.1
      end
    end
  end

  def join(room)
    options = load_system_conf
    room['user'] = local_user(options) if !room['user']['nickname']
    if room['server']['auth'] and room['user']['password']
      options['nickname'] = "#{room['user']['nickname']}$#{room['user']['password']}"
    else
      options['nickname'] = room['user']['nickname']
    end
    options['lastip'] = room['server']['ip']
    options['lastport'] = room['server']['port'].to_s
    options['roompass'] = room['name']
    save_system_conf(options)
    run_ygopro('-j')
  end

  def rich_join(room)
    if room['players'] && ((room['players']['0'] && room['players']['0']['avatar']) || ((room['players']['1'] && room['players']['1']['avatar'])))
      require 'rmagick'
      require "base64"
      bg_path = File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
      bg = Magick::ImageList.new.from_blob IO.binread bg_path
      finished = 0
      if room['players']['0'] && room['players']['0']['avatar']
        if room['players']['0']['avatar'][0, 5] == 'data:'
          require 'data-uri'
          avatar_player = Magick::ImageList.new.from_blob DataURI.decode(room['players']['0']['avatar'])
          avatar_player.crop_resized!(96, 96, Magick::NorthGravity)
          bg.composite!(avatar_player, 330, 60, Magick::CopyCompositeOp)
          finished += 1
        elsif File.file? avatar_player_path = File.join('avatars', File.basename(room['players']['0']['avatar']))
          avatar_player = Magick::ImageList.new.from_blob IO.binread avatar_player_path
          avatar_player.crop_resized!(96, 96, Magick::NorthGravity)
          bg.composite!(avatar_player, 330, 60, Magick::CopyCompositeOp)
          finished += 1
        else
          http = EventMachine::HttpRequest.new(room['players']['0']['avatar'], connect_timeout: 5, inactivity_timeout: 10).get redirects: 5
          http.callback {
            if http.response_header.status == 200
              avatar_player = Magick::ImageList.new.from_blob http.response
              avatar_player.crop_resized!(96, 96, Magick::NorthGravity)
              bg.composite!(avatar_player, 330, 60, Magick::CopyCompositeOp)
              Dir.mkdir 'avatars' unless File.directory? 'avatars'
              IO.binwrite avatar_player_path, http.response
            end
            finished += 1
            if finished == 2
              File.rename bg_path, File.join(File.dirname(bg_path), 'bg_origin.jpg')
              bg.write File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
              parse_uri(room['url_mycard'])
              EventMachine::Timer.new(3) { File.rename File.join(File.dirname(bg_path), 'bg_origin.jpg'), bg_path }
            end
          }
          http.errback { |http|
            puts http
            finished += 1
            if finished == 2
              File.rename bg_path, File.join(File.dirname(bg_path), 'bg_origin.jpg')
              bg.write File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
              parse_uri(room['url_mycard'])
              EventMachine::Timer.new(3) { File.rename File.join(File.dirname(bg_path), 'bg_origin.jpg'), bg_path }
            end
          }
        end
      else
        finished += 1
      end

      if room['players']['1'] && room['players']['1']['avatar']
        if room['players']['1']['avatar'][0, 5] == 'data:'
          require 'data-uri'
          avatar_opponent = Magick::ImageList.new.from_blob DataURI.decode(room['players']['1']['avatar'])
          avatar_opponent.crop_resized!(96, 96, Magick::NorthGravity)
          bg.composite!(avatar_opponent, 989-96, 60, Magick::CopyCompositeOp)
          finished += 1
        elsif File.file? avatar_opponent_path = File.join('avatars', File.basename(room['players']['1']['avatar']))
          avatar_opponent = Magick::ImageList.new.from_blob IO.binread avatar_opponent_path
          avatar_opponent.crop_resized!(96, 96, Magick::NorthGravity)
          bg.composite!(avatar_opponent, 989-96, 60, Magick::CopyCompositeOp)
          finished += 1
        else
          http = EventMachine::HttpRequest.new(room['players']['1']['avatar'], connect_timeout: 5, inactivity_timeout: 10).get redirects: 5
          http.callback {
            if http.response_header.status == 200
              avatar_opponent = Magick::ImageList.new.from_blob http.response
              avatar_opponent.crop_resized!(96, 96, Magick::NorthGravity)
              bg.composite!(avatar_opponent, 989-120, 60, Magick::CopyCompositeOp)
              Dir.mkdir 'avatars' unless File.directory? 'avatars'
              IO.binwrite avatar_opponent_path, http.response
            end
            finished += 1
            if finished == 2
              File.rename bg_path, File.join(File.dirname(bg_path), 'bg_origin.jpg')
              bg.write File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
              parse_uri(room['url_mycard'])
              EventMachine::Timer.new(3) { File.rename File.join(File.dirname(bg_path), 'bg_origin.jpg'), bg_path }
            end
          }
          http.errback { |http|
            finished += 1
            if finished == 2
              File.rename bg_path, File.join(File.dirname(bg_path), 'bg_origin.jpg')
              bg.write File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
              parse_uri(room['url_mycard'])
              EventMachine::Timer.new(3) { File.rename File.join(File.dirname(bg_path), 'bg_origin.jpg'), bg_path }
            end
          }
        end
      else
        finished += 1
      end

      if finished == 2
        File.rename bg_path, File.join(File.dirname(bg_path), 'bg_origin.jpg')
        bg.write File.join(File.dirname(Config['ygopro']['path']), 'textures', 'bg.jpg')
        parse_uri(room['url_mycard'])
        EventMachine::Timer.new(3) { File.rename File.join(File.dirname(bg_path), 'bg_origin.jpg'), bg_path }
      end
    else
      parse_uri(room['url_mycard'])
    end
  end

  def deck(deck)
    File.rename(File.join(File.dirname(Config['ygopro']['path']), 'deck', deck + '.ydk'), File.join(File.dirname(Config['ygopro']['path']), 'deck', deck.gsub!(' ', '_') + '.ydk')) if deck[' ']
    options = load_system_conf
    options['lastdeck'] = deck
    save_system_conf(options)
    run_ygopro('-d')
  end

  def replay(replay)
    require 'fileutils'
    moved_replay_directory = File.join(File.dirname(Config['ygopro']['path']), 'replay', 'stashed')
    files = Dir.glob(File.join(File.dirname(Config['ygopro']['path']), 'replay', '*.yrp'))
    files.delete File.join(File.dirname(Config['ygopro']['path']), 'replay', replay+'.yrp')
    FileUtils.mkdir_p moved_replay_directory unless File.directory? moved_replay_directory
    FileUtils.mv files, moved_replay_directory
    run_ygopro('-r')
  end

  def local_user(system_conf=load_system_conf)
    nickname, password = system_conf['nickname'] ? system_conf['nickname'].split('$') : []
    {'nickname' => nickname, 'password' => password}
  end

  def parse(command)
    case command
      when 'register'
        register
      when 'registed'
        registed?
      when 'mycard:///'
        service
      when /^mycard:\/\/(.*)$/
        parse_uri(command)
      when /^.*\.(?:ydk|yrp)$/
        parse_path(command) #解析函数可以分开
      when /^join:(.*)$/
        room = JSON.parse $1
        rich_join(room)
    end
  end

  def parse_path(path)
    require 'fileutils'
    require 'pathname'
    path = Pathname.new(path).cleanpath.to_s.gsub('\\', '/')

    case File.extname(path)
      when '.ydk'
        deck_directory = File.expand_path('deck', File.dirname(Config['ygopro']['path']))
        unless File.expand_path(File.dirname(path)) == deck_directory
          Dir.mkdir(deck_directory) unless File.directory?(deck_directory)
          FileUtils.copy(path, deck_directory)
        end
        deck(File.basename(path, '.ydk'))
      when '.yrp'
        replay_directory = File.expand_path('replay', File.dirname(Config['ygopro']['path']))
        unless File.expand_path(File.dirname(path)) == replay_directory
          Dir.mkdir(replay_directory) unless File.directory?(replay_directory)
          FileUtils.copy(path, replay_directory)
        end
        replay(File.basename(path, '.yrp'))
    end
  end

  def parse_uri(uri)
    require 'uri'

    if uri[0, 9] == 'mycard://'
      file = URI.unescape uri[9, uri.size-9]
      uri = "http://" + URI.escape(file)
    else
      uri = file
    end
    case file
      when /^(.*\.yrp)$/i
        require 'open-uri'
        #fix File.basename
        $1 =~ /(.*)(?:\\|\/)(.*?\.yrp)/
        src = open(uri, 'rb') { |src| src.read }
        Dir.mkdir("replay") unless File.directory?("replay")
        open('replay/' + $2, 'wb') { |dest| dest.write src }
        replay('replay/' + $2)
      when /^(.*\.ydk)$/i
        require 'open-uri'
        #fix File.basename
        $1 =~ /(.*)(?:\\|\/)(.*?)\.ydk/
        src = open(uri, 'rb') { |src| src.read }
        Dir.mkdir(File.join(File.dirname(Config['ygopro']['path']), 'deck')) unless File.join(File.dirname(Config['ygopro']['path']), 'deck')
        open(File.join(File.dirname(Config['ygopro']['path']), 'deck', $2+'.ydk'), 'wb') { |dest| dest.write src }
        deck($2)
      when /^(?:(.+?)(?:\:(.+?))?\@)?([\d\.]+)\:(\d+)(?:\/(.*))$/
        join({
                 'name' => $5.to_s,
                 'user' => {
                     'nickname' => $1,
                     'password' => $2
                 },
                 'server' => {
                     'ip' => $3,
                     'port' => $4.to_i,
                     'auth' => !!$2
                 }
             })
    end
  end

#monkey patch for exerb & addressable
  if defined? ExerbRuntime
    module Addressable
      module IDNA
        module File
          class <<self
            def join(*args)
            end

            def expand_path(*args)
            end

            def dirname(*args)
            end

            def open(*args)
              result = ExerbRuntime.open('unicode.data')
              if block_given?
                begin
                  yield result
                ensure
                  result.close
                end
              end
            end
          end
        end
      end
    end
  end

  save_config

  if ARGV.first
    parse ARGV.first.dup.force_encoding(System_Encoding).encode!(Encoding::UTF_8)
  else
    register if !registed?
    if File.file? 'nw.exe'
      spawn 'nw.exe', '.'
    elsif File.file? 'node-webkit/nw.exe'
      spawn 'node-webkit/nw.exe', '.'
    elsif File.file? 'ruby\bin\rubyw.exe'
      spawn 'ruby\bin\rubyw.exe', '-KU', 'lib/main.rb'
    else
      System.web(Config['url'])
    end
    service
  end
rescue SystemExit
rescue Exception => exception
  error = "程序出现了错误，请把你的操作及以下信息发送至zh99998@gmail.com来帮助我们完善程序
an error occurs, please send your operation and message below to zh99998@gmail.com

#{exception.inspect.encode(Encoding::UTF_8)}
  #{exception.backtrace.join("\n").encode(Encoding::UTF_8)}"
  open('error.txt', 'w:utf-8') { |f| f.write error }
  spawn 'notepad', 'error.txt'
end
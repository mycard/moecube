#encoding: UTF-8
if !File.file? 'data/allcards.dll'
  puts "请放到iDuel目录下运行"
  exit
end

cards = IO.readlines('data/allcards.dll').size / 2
puts "卡片总计 #{cards} 张"

if File.file? 'data/config.ini'
  require 'inifile'
  config = IniFile.new IO.read('data/config.ini', mode: 'rb:BOM|UTF-16LE:UTF-8')
  path = config['Config'] && config['Config']['CardImagePath']
end

if !path or !File.directory? path
  require 'win32/registry'
  path = Win32::Registry::HKEY_CURRENT_USER.open('Software\OCGSOFT\Cards') { |reg| reg['Path'] } rescue ''
  path.force_encoding(Encoding::GBK).encode!(Encoding::UTF_8)
end

if !path or !File.directory? path
  Dir.mkdir 'data' unless File.directory? 'data'
  path = 'data/image'
end

puts "本地卡图路径 #{path}"
Dir.mkdir path unless File.directory? path

def batch_download(main_url, files, content_type=nil)
  connections = {}
  count = {total: files.size, error: 0}
  [10*100, files.size].min.times { do_download(main_url, files, content_type, count, connections) }
end

def do_download(main_url, files, content_type, count, connections)
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
    puts File.basename local_path
    count[:error] = 0
    count[:total] -= 1
    if http.response_header['CONNECTION'] != 'keep-alive'
      connection.close
      connections.delete(connection)
      do_download(main_url, files, content_type, count, connections) while !files.empty? and (connections.size < 10 or connections.values.min < 100)
    end

    if http.response_header.status == 200 and (!content_type or http.response_header['CONTENT_TYPE'] == content_type)
      IO.binwrite local_path, http.response
    else
      puts http.response_header.http_status
    end

    if count[:total].zero?
      connections.each_key { |connection| connection.close }
      connections.clear
      puts 'all done'
      EM.stop
    end
  }.errback { |http|
    puts http.error
    connection.close
    connections.delete(connection)
    files[remote_path] = local_path
    count[:error] += 1
    if count[:error] <= 10*100
      do_download(main_url, files, content_type, count, connections) while !files.empty? and (connections.size < 10 or connections.values.min < 100)
    else
      connections.each_key { |connection| connection.close }
      connections.clear
      puts 'network error'
      EM.stop
    end
  }
end

cards_to_download = (1..cards).to_a - Dir.glob(File.expand_path '*.jpg', path).collect { |file| File.basename(file, '.jpg').to_i }


puts "需要下载 #{cards_to_download.size} 张"

exit if cards_to_download.empty?

#monkey patch for exerb & addressable
if defined? ExerbRuntime
  require 'stringio'
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

require 'em-http-request'
EventMachine.run do
  http = EventMachine::HttpRequest.new('http://p.ocgsoft.cn/:osid.jpg').get redirects: 10
  http.callback { |http|
    main_url = http.last_effective_url
    puts "获取卡图下载地址: #{main_url}"
    files = {}
    cards_to_download.each { |card_id| files[main_url.path.gsub(':osid', card_id.to_s)] = File.join(path, card_id.to_s + '.jpg') }
    batch_download(main_url.to_s, files, 'image/jpeg')
  }
end
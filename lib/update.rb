require 'open-uri'
require "fileutils"
require_relative 'card'
module Update
  Version = '1.3.8'
  URL = "https://my-card.in/mycard/update.json?version=#{Version}"
  class <<self
    attr_reader :thumbnails, :images
    attr_accessor :status

    def start
      Dir.glob("mycard-update-*-*.zip") do |file|
        file =~ /mycard-update-(.+?)-(.+?)\.zip/
        if $1 <= Version and $2 > Version
          $log.info('安装更新') { file }
          WM::set_caption("MyCard - 正在更新 #{Version} -> #{$2}", "MyCard")
          require 'zip/zip'
          Zip::ZipFile::open(file) do |zip|
            zip.each do |f|
              if !File.directory?(f.name)
                FileUtils.mkdir_p(File.dirname(f.name))
              end
              f.extract { true }
            end
          end rescue $log.error('安装更新出错') { file+$!.inspect+$!.backtrace.inspect }
          Version.replace $2
          File.delete file
          @updated = true
        end
      end
      if @updated
        require 'rbconfig'
        spawn(File.join(RbConfig::CONFIG["bindir"],RbConfig::CONFIG[Windows ? "RUBYW_INSTALL_NAME" : "RUBY_INSTALL_NAME"] + RbConfig::CONFIG["EXEEXT"]) + " -KU lib/main.rb")
        $scene = nil
      end
      @images = []
      @thumbnails = []

      @status = '正在检查更新'
      @updated = false
      (Thread.new do
        open(URL) do |file|
          require 'json'
          reply = file.read
          $log.info('下载更新-服务器回传') { reply }
          reply = JSON.parse(reply)
          $log.info('下载更新-解析后') { reply.inspect }
          reply.each do |fil|
            name = File.basename fil
            @status = "正在下载更新#{name}"
            open(fil, 'rb') do |fi|
              $log.info('下载完毕') { name }
              @updated = true
              open(name, 'wb') do |f|
                f.write fi.read
              end
            end rescue $log.error('下载更新') { '下载更新失败' }
          end
        end rescue $log.error('检查更新') { '检查更新失败' }
        if @updated
          require_relative 'widget_msgbox'
          Widget_Msgbox.new('mycard', '下载更新完毕，点击确定重新运行mycard并安装更新', :ok => "确定") {
            require 'rbconfig'
            spawn(File.join(RbConfig::CONFIG["bindir"],RbConfig::CONFIG[Windows ? "RUBYW_INSTALL_NAME" : "RUBY_INSTALL_NAME"] + RbConfig::CONFIG["EXEEXT"]) + " -KU lib/main.rb")
            $scene = nil
          }
        end
        if File.file? "ygocore/cards.cdb"
          require 'sqlite3'
          db = SQLite3::Database.new("ygocore/cards.cdb")
          db.execute("select id from datas") do |row|
            @thumbnails << row[0]
          end
          @images.replace @thumbnails

          if !File.directory?('ygocore/pics/thumbnail')
            FileUtils.mkdir_p('ygocore/pics/thumbnail')
          end

          existed_thumbnails = []
          Dir.foreach("ygocore/pics/thumbnail") do |file|
            if file =~ /(\d+)\.jpg/
              existed_thumbnails << $1.to_i
            end
          end
          @thumbnails -= existed_thumbnails
          existed_images = []
          Dir.foreach("ygocore/pics") do |file|
            if file =~ /(\d+)\.jpg/
              existed_images << $1.to_i
            end
          end
          @images -= existed_images
          existed_images = []
          if (!@images.empty? or !@thumbnails.empty?) and File.file?("#{Card::PicPath}/1.jpg")
            db_mycard = SQLite3::Database.new("data/data.sqlite")

            db_mycard.execute("select id, number from `yu-gi-oh` where number in (#{(@images+@thumbnails).uniq.collect { |number| "'%08d'" % number }.join(',')})") do |row|
              id = row[0]
              number = row[1].to_i
              src = "#{Card::PicPath}/#{id}.jpg"
              dest = "ygocore/pics/#{number}.jpg"
              dest_thumb = "ygocore/pics/thumbnail/#{number}.jpg"
              if File.file?(src)
                @status = "检测到存在iDuel卡图 正在导入 #{id}.jpg"
                existed_images << number
                if !File.exist?(dest)
                  FileUtils.copy_file(src, dest)
                  FileUtils.copy_file(src, dest_thumb)
                end
              end
            end
          end
          @images -= existed_images
          @thumbnails -= existed_images
          @thumbnails = (@thumbnails & @images) + (@thumbnails - @images)
          unless @thumbnails.empty? and @images.empty?
            $log.info('待下载的完整卡图') { @images.inspect }
            $log.info('待下载的缩略卡图') { @thumbnails.inspect }

            open('https://my-card.in/cards/image.json') do |f|
              image_index = JSON.parse(f.read)
              $log.info('卡图路径'){image_index}
              url = image_index['url']
              uri = URI(url)
              image_req = uri.path
              image_req += '?' + uri.query if uri.query
              image_req += '#' + uri.fragment if uri.fragment

              url = image_index['thumbnail_url']
              uri = URI(url)
              thumbnail_req = uri.path
              thumbnail_req += '?' + uri.query if uri.query
              thumbnail_req += '#' + uri.fragment if uri.fragment

              require 'net/http/pipeline'
              @thumbnails_left = @thumbnails.size
              @images_left = @images.size
              @error_count = 0
              threads = 5.times.collect do
                thread = Thread.new do
                  Net::HTTP.start uri.host, uri.port do |http|
                    http.pipelining = true
                    begin
                      list = @thumbnails
                      ids = []
                      while !@thumbnails.empty?
                        ids.replace @thumbnails.pop(100)
                        reqs = ids.reverse.collect { |id| Net::HTTP::Get.new thumbnail_req.gsub(':id', id.to_s) }
                        http.pipeline reqs do |res|
                          @status = "正在下载卡图 (剩余: 缩略#{@thumbnails_left} / 完整#{@images_left} #{"错误: #{@error_count}" if @error_count > 0})"
                          @thumbnails_left -= 1
                          id = ids.pop
                          if res.code[0] == '2' #http 2xx
                            next if File.file? "ygocore/pics/thumbnail/#{id}.jpg"
                            content = res.body
                            open("ygocore/pics/thumbnail/#{id}.jpg", 'wb') {|local|local.write content}
                          else
                            $log.warn("下载缩略卡图#{id}出错"){res}
                            @error_count += 1
                          end
                        end
                      end
                      list = @images
                      ids = []
                      while !@images.empty?
                        ids.replace @images.pop(100)
                        reqs = ids.reverse.collect { |id| Net::HTTP::Get.new image_req.gsub(':id', id.to_s) }
                        http.pipeline reqs do |res|
                          @status = "正在下载卡图 (剩余: 缩略#{@thumbnails_left} / 完整#{@images_left} #{"错误: #{@error_count}" if @error_count > 0})"
                          @images_left -= 1
                          id = ids.pop
                          if res.code[0] == '2' #http 2xx
                            next if File.file? "ygocore/pics/#{id}.jpg"
                            content = res.body
                            open("ygocore/pics/#{id}.jpg", 'wb') {|local|local.write content}
                          else
                            $log.warn("下载完整卡图#{id}出错"){res}
                            @error_count += 1
                          end
                        end
                      end
                    rescue
                      $log.error('卡图下载') { [$!.inspect, *$!.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
                      list.concat ids
                    end
                  end rescue $log.error('卡图下载线程出错') { $!.inspect.force_encoding("UTF-8") }
                end
                thread.priority = -1
                thread
              end
              threads.each { |thread| thread.join }
            end
          end
        end rescue $log.error('卡图更新') { [$!.inspect, *$!.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
        @status = nil
      end).priority = -1
    end
  end
end

require 'open-uri'
require "fileutils"
require_relative 'card'
module Update
  Version = '0.5.0'
  URL = "http://card.touhou.cc/mycard/update.json?version=#{Version}"
  class <<self
    attr_reader :thumbnails, :images, :status
    def start
      Dir.glob("mycard-update-*-*.zip") do |file|
        file =~ /mycard-update-(.+?)-(.+?)\.zip/
        if $1 <= Version and $2 > Version
          $log.info('安装更新'){file}
          WM::set_caption("MyCard - 正在更新 #{Version} -> #{$2}", "MyCard")
          require 'zip/zip'
          Zip::ZipFile::open(file) do |zip|
            zip.each do |f|
              if !File.directory?(f.name)
                FileUtils.mkdir_p(File.dirname(f.name)) 
              end
              f.extract{true}
            end
          end rescue $log.error('安装更新出错'){file+$!.inspect+$!.backtrace.inspect}
          Version.replace $2
          File.delete file
          @updated = true
        end
      end
      if @updated
        IO.popen('./mycard')
        $scene = nil
      end
      @images = []
      @thumbnails = []
      
      @status = '正在检查更新'
      Thread.new do
        open(URL) do |file|
          require 'json'
          reply = file.read
          $log.info('下载更新-服务器回传'){reply}
          reply = JSON.parse(reply)
          $log.info('下载更新-解析后'){reply.inspect}
          reply.each do |fil|
            name = File.basename fil
            @status.replace "正在下载更新#{name}"
            open(fil, 'rb') do |fi|
              $log.info('下载完毕'){name}
              open(name, 'wb') do |f|
                f.write fi.read
              end
            end rescue nil
          end
          if File.file? "ygocore/cards.cdb"
            require 'sqlite3'
            db = SQLite3::Database.new( "ygocore/cards.cdb" )
            db.execute( "select id from datas" ) do |row|
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
            $log.info('待下载的缩略卡图'){@thumbnails.inspect}
            existed_images = []
            Dir.foreach("ygocore/pics") do |file|
              if file =~ /(\d+)\.jpg/
                existed_images << $1.to_i
              end
            end
            @images -= existed_images
            existed_images = []
            if (!@images.empty? or !@thumbnails.empty?) and File.file?("#{Card::PicPath}/1.jpg")
              db_mycard = SQLite3::Database.new( "data/data.sqlite" )
              can_link = true
              internal_can_link = true
              
              db_mycard.execute( "select id, number from `yu-gi-oh` where number in (#{(@images+@thumbnails).uniq.collect{|number|"'%08d'" % number}.join(',')})" ) do |row|
                id = row[0]
                number = row[1].to_i
                existed_images << number
                src = "#{Card::PicPath}/#{id}.jpg"
                dest = "ygocore/pics/#{number}.jpg"
                dest_thumb = "ygocore/pics/thumbnail/#{number}.jpg"
                if File.file?(src)
                  @status.replace "检测到存在iDuel卡图 正在导入 #{id}.jpg"
                  if !File.exist?(dest)
                    if can_link
                      File.link(src, dest) rescue can_link = false
                    end
                    if !can_link
                      FileUtils.copy_file(src, dest)
                    end
                    if !File.exist?(dest_thumb)
                      if internal_can_link
                        File.link(dest, dest_thumb) rescue internal_can_link = false
                      end
                      if !internal_can_link
                        FileUtils.copy_file(dest, dest_thumb)
                      end
                    end
                  elsif !File.exist?(dest_thumb)
                    if can_link
                      File.link(src, dest_thumb) rescue can_link = false
                    end
                    if !can_link
                      FileUtils.copy_file(src, dest_thumb)
                    end
                  end
                end
              end
            end
            @images -= existed_images
            @thumbnails -= existed_images
            @thumbnails = (@thumbnails & @images) + (@thumbnails - @images)
            unless @thumbnails.empty? and @images.empty?
              $log.info('待下载的完整卡图'){@images.inspect}
              threads = 5.times.collect do 
                thread = Thread.new do
                  while number = @thumbnails.pop
                    @status.replace "正在下载缩略卡图 (剩余#{@thumbnails.size}张)"
                    open("http://card.touhou.cc/images/cards/ygocore/thumbnail/#{number}.jpg", 'rb') do |remote|
                      next if File.file? "ygocore/pics/thumbnail/#{number}.jpg"
                      open("ygocore/pics/thumbnail/#{number}.jpg", 'wb') do |local|
                        local.write remote.read
                      end
                    end rescue nil
                  end
                  while number = @images.pop
                    @status.replace "正在下载完整卡图 (剩余#{@images.size}张)"
                    open("http://card.touhou.cc/images/cards/ygocore/#{number}.jpg", 'rb') do |remote|
                      next if File.file? "ygocore/pics/#{number}.jpg"
                      open("ygocore/pics/#{number}.jpg", 'wb') do |local|
                        local.write remote.read
                      end
                    end rescue nil
                  end 
                end
                thread.priority = -1
                thread
              end
              threads.each{|thread|thread.join}
            end
          end
        end rescue nil
        @status = nil
      end.priority = -1
    end
    def copy(src, dest, can_link)
      if can_link
        File.link(src, dest)
      else
        open(src, 'rb') do |src|
          open(dest, 'wb') do |dest|
            dest.write src.read
          end
        end
      end
    end
  end
end
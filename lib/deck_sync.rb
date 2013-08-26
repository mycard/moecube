module Deck_Sync
  require_relative 'deck'
  class <<self
    def start
      Update.status = '正在同步卡组'
      require 'open-uri'
      require 'uri'
      require 'net/http'
      require 'json'
      require 'date'
      Thread.new {
        just_updated = []
        $log.info('下载卡组') { "https://my-card.in/decks/?user=#{URI.escape $game.user.id.bare.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}" }
        open("https://my-card.in/decks/?user=#{URI.escape $game.user.id.bare.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}") { |list|
          Dir.mkdir File.dirname(Ygocore.ygocore_path) if !File.directory? File.dirname(Ygocore.ygocore_path)
          Dir.mkdir File.join File.dirname(Ygocore.ygocore_path), 'deck' if !File.directory? File.join File.dirname(Ygocore.ygocore_path), 'deck'
          JSON.parse(list.read).each { |deck|
            file = File.join(File.dirname(Ygocore.ygocore_path), 'deck', "#{deck['name']}.ydk")
            if (!File.file?(file) || DateTime.parse(deck['updated_at']).to_time > File.mtime(file))
              open(file, 'w') { |f|
                main = []
                side = []
                deck['cards'].each { |card_usage|
                  card_usage['count'].times {
                    (card_usage['side'] ? side : main).push card_usage['card_id']
                  }
                }
                f.puts "#mycard deck sync #{deck['user']}"
                f.puts "#main"
                f.puts main.join("\n")
                f.puts "!side"
                f.puts side.join("\n")
              }
              File.utime(Time.now, DateTime.parse(deck['updated_at']).to_time, file)
            end
            if DateTime.parse(deck['updated_at']).to_time >= File.mtime(file)
              just_updated.push file
            end
          }
        } rescue $log.error('卡组下载') { [$!.inspect, *$!.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
        Thread.new { watch } unless @watching
        @watching = true
        Dir.glob("#{File.dirname(Ygocore.ygocore_path)}/deck/*.ydk").each { |deck|
          next if just_updated.include? deck
          update(deck)
        }
        Update.status = nil
      }
    end

    def watch
      require 'fssm'
      FSSM.monitor("#{File.dirname(Ygocore.ygocore_path)}/deck", '*.ydk') do
        update { |base, relative| Deck_Sync.update "#{base}/#{relative}" }
        delete { |base, relative| Deck_Sync.delete "#{base}/#{relative}" }
        create { |base, relative| Deck_Sync.update "#{base}/#{relative}" }
      end
    end

    def update(deck)
      Update.status = "正在同步卡组: #{File.basename(deck, ".ydk")}"
      begin
        path = "/decks/?#{Deck.ygopro_deck_to_url_param(deck)}&user=#{URI.escape $game.user.id.bare.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}&updated_at=#{URI.escape DateTime.now.iso8601, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}"
        $log.info("卡组上传") { path }
        req = Net::HTTP::Put.new path
        response = Net::HTTP.start('my-card.in', 443, use_ssl: true) { |http| http.request(req) }
      rescue
        $log.error('卡组上传') { [$!.inspect, *$!.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
      end
      Update.status = nil
    end

    def delete(deck)
      Update.status = "正在同步卡组: #{File.basename(deck, ".ydk")}"
      begin
        path = "/decks/?name=#{URI.escape File.basename(deck, ".ydk"), Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}&user=#{URI.escape $game.user.id.bare.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")}"
        $log.info("卡组删除") { path }
        req = Net::HTTP::Delete.new path
        response = Net::HTTP.start('my-card.in', 443, use_ssl: true) { |http| http.request(req) }
      rescue
        $log.error('卡组删除') { [$!.inspect, *$!.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") }
      end
      Update.status = nil
    end
  end
end
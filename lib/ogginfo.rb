# $Id$
# = Description
#
# ruby-ogginfo gives you access to low level information on ogg files
# (bitrate, length, samplerate, encoder, etc... ), as well as tag.
# It is written in pure ruby.
#
#
# = Download
#
#
# http://rubyforge.org/projects/ruby-ogginfo/
#
#
# = Generate documentation
# 
# rdoc --template=kilmer ogginfo.rb
#
#
# = Changelog
#
# [0.1 20/06/2004]
# 
# * first public version
#
#
# License:: Ruby
# Author:: Guillaume Pierronnet (mailto:moumar_AT__rubyforge_DOT_org)
# Website:: http://ruby-ogginfo.rubyforge.org/
#
# see http://www.xiph.org/ogg/vorbis/docs.html for documentation on vorbis format
# http://www.xiph.org/ogg/vorbis/doc/v-comment.html

require "iconv"

# Raised on any kind of error related to ruby-ogginfo
class OggInfoError < StandardError ; end

class OggInfo
=begin
  FIELDS_MAPPING = {
    "title" => "songname",
    "artist" => "artist",
    "album" => "album",
    "date" => "year",
    "description" => "comment",
    "tracknumber" => "tracknum",
    "genre" => "genre"
  }
=end
  attr_reader :channels, :samplerate, :bitrate, :tag, :length

  def initialize(filename, charset = "iso-8859-1")
    begin
      @file = File.new(filename, "rb")
      find_page()
      extract_infos()
      find_page()
      extract_tag(charset)
      extract_end()
    ensure
      close
    end
  end

  # "block version" of ::new()
  def self.open(filename)
    m = self.new(filename)
    ret = nil
    if block_given?
      begin
        ret = yield(m)
      ensure
        m.close
      end
    else
      ret = m
    end
    ret
  end

  def close
      @file.close if @file and not @file.closed?
  end

  def hastag?
    not @tag.empty?
  end
  
  def to_s
    "channels #{@channels} samplerate #{@samplerate} bitrate #{@bitrate} length #{@length}"
  end

private
  def find_page
    header = 'OggS' # 0xf4 . 0x67 . 0x 67 . 0x53
    bytes = @file.read(4)
    bytes_read = 4

    while header != bytes
      #raise OggInfoError if bytes_read > 4096 or @file.eof? #bytes.nil?
      raise OggInfoError if @file.eof? #bytes.nil?
      bytes.slice!(0)
      char = @file.read(1)
      bytes_read += 1
      bytes << char
    end
  end

  def extract_infos
#    @bitrate = {}
    @file.seek(35, IO::SEEK_CUR) # seek after "vorbis"
#    @channels, @samplerate, @bitrate["upper"], @bitrate["nominal"], @bitrate["lower"] = 
    @channels, @samplerate, up_br, br, down_br = 
      @file.read(17).unpack("CV4")
    @bitrate = 
      if br == 0
        if up == 2**32 - 1 or down == 2**32 - 1 
	  0
	else
	  (up_br + down_br)/2
	end
      else 
        br
      end
  end

  def extract_tag(charset)
    @tag = {}
    @file.seek(22, IO::SEEK_CUR)
    segs = @file.read(1).unpack("C")[0]
    @file.seek(segs + 7, IO::SEEK_CUR)
    size = @file.read(4).unpack("V")[0]
    @file.seek(size, IO::SEEK_CUR)
    tag_size = @file.read(4).unpack("V")[0]
    #ic = Iconv.new(charset, "utf8")
    tag_size.times do |i|
      size = @file.read(4).unpack("V")[0]
      com = @file.read(size)
      comment = com
      comment.force_encoding "UTF-8"
   #   begin
   #     comment = ic.iconv( com )
   #   rescue Iconv::IllegalSequence, Iconv::InvalidCharacter
   #     comment = com
   #   end
      key, val = comment.split(/=/)
      @tag[key.downcase] = val
    end
    #ic.close
  end

  def extract_end
    begin #Errno::EINVAL
      @file.seek(-5000, IO::SEEK_END) #FIXME size of seeking
      find_page
      pos = @file.read(6).unpack("x2 V")[0] #FIXME pos is int64
      @length = pos.to_f / @samplerate
    rescue Errno::EINVAL
      @length = 0
    end
  end
end

if $0 == __FILE__
  while filename = ARGV.shift
    puts "Getting info from #{filename}"
    begin
      ogg = OggInfo.new(filename)
    rescue OggInfoError
     puts "error: doesn't appear to be an ogg file"
    else
      puts ogg
      ogg.tag.each { |key, value|
        puts "#{key} => #{value}"
      }
    end
    puts
  end
end
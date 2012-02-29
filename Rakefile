#encoding: UTF-8
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
#require 'rake/testtask'

Windows = RUBY_PLATFORM["mingw"] || RUBY_PLATFORM["mswin"]
if Windows
  STDOUT.set_encoding "GBK", "UTF-8"
  STDERR.set_encoding "GBK", "UTF-8"
end
#在windows上UTF-8脚本编码环境中  Dir.glob无法列出中文目录下的文件 所以自己写个递归
def list(path)
	result = []
	Dir.foreach(path) do |file|
		next if file == "." or file == ".."
    result << "#{path}/#{file}"
		result.concat list(result.last) if File.directory? result.last
	end
	result
end

spec = Gem::Specification.new do |s|
  s.name = 'mycard'
  s.version = '0.4.0'
  s.extra_rdoc_files = ['README.txt', 'LICENSE.txt']
  s.summary = 'a card game'
  s.description = s.summary
  s.author = 'zh99998'
  s.email = 'zh99998@gmail.com'
  s.homepage = 'http://card.touhou,cc'
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE.txt README.txt replay)
  %w{lib audio data fonts graphics}.each{|dir|s.files.concat list(dir)}
  if Windows
    s.files += %w(mycard.exe) + list("ruby")
  else
    s.files += %w(install.sh)
  end
  s.require_path = "lib"
  #s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  if Windows
    p.need_zip = true
    p.zip_command = '../7z.exe a -tzip'
    def p.zip_file
      "#{package_name}-win32.zip"
    end
  else
    p.need_tar = true
  end
end

Rake::RDocTask.new do |rdoc|
  files =['README.txt', 'LICENSE.txt', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.txt" # page to start on
  rdoc.title = "Mycard Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

CLOBBER.include %w(error-程序出错请到论坛反馈.txt log.log profile.log config.yml doc) + list('replay') + list('.').keep_if{|file|File.basename(file) == "Thumbs.db"} + list("graphics/avatars").keep_if{|file|File.basename(file) =~ /.*_(?:small|middle|large)\.png/}
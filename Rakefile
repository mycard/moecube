require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
#require 'rake/rdoctask'
#require 'rake/testtask'

Windows = RUBY_PLATFORM["mingw"] || RUBY_PLATFORM["mswin"]
spec = Gem::Specification.new do |s|
  s.name = 'mycard'
  s.version = '0.1.0'
  s.extra_rdoc_files = ['README.txt', 'LICENSE.txt']
  s.summary = 'a card game'
  s.description = s.summary
  s.author = 'zh99998'
  s.email = 'zh99998@gmail.com'
  s.homepage = 'http://card.touhou,cc'
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE.txt README.txt config.yml replay) + Dir.glob("{lib,audio,data,fonts,graphics}/**/*")
  if Windows
    s.files += %w(mycard.cmd) + Dir.glob("{ruby}/**/*")
  else
    s.files += %w(mycard.sh)
  end
  s.require_path = "lib"
  #s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  if Windows
    p.need_zip = true
    p.zip_command = '7z a -tzip'
  else
    p.need_tar = true
  end
end

CLOBBER.include %w(log.log err.log) + Dir.glob("{replay}/**/*") + Dir.glob("**/Thumbs.db") + Dir.glob("graphics/avatars/*_*.png")
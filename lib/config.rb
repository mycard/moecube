require 'yaml'
require_relative 'resolution'
Config = Module.new
module Config
  module_function
  def load(file="config.yml")
    config = YAML.load_file(file) rescue {}
    config = {} unless config.is_a? Hash
    config['bgm'] = true if config['bgm'].nil?
    config['screen'] ||= {}
    config['screen']['width'], config['screen']['height'] = Resolution.default unless Resolution.all.include? [config['screen']['width'], config['screen']['height']]
    config['i18n'] ||= {}
    config['i18n']['locale'] ||= "#{Locale.current.language}-#{Locale.current.region}"
    I18n.locale = config['i18n']['locale']
    config
  end
  def save(config=$config, file="config.yml")
    File.open(file, "w") { |file| YAML.dump(config, file) }
  end
end
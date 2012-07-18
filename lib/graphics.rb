module Graphics
  module_function
  Ext = ['.png', '.jpg', '.gif']

  def load(directory, filename, alpha=true)
    extname  = File.extname(filename)
    path = "graphics/#{directory}/#{File.dirname(filename)}/#{File.basename(filename, extname)}"

    result = if extname.empty?
      Ext.each do |ext|
        result = load_file(path, ext)
        break result if result
      end
    else
      load_file(path, extname)
    end
    raise 'file not exist' if result.nil?

    if alpha
      result.display_format_alpha
    else
      result.display_format
    end
  end

  def load_file(path, ext)
    path_with_resolution = "#{path}-#{$config['screen']['width']}x#{$config['screen']['height']}#{ext}"
    if File.file? path_with_resolution
      Surface.load path_with_resolution
    elsif File.file? path += ext
      Surface.load path
    end
  end
end
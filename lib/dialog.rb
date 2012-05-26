module Dialog
  #选择文件对话框
  require 'win32api'
  GetOpenFileName = Win32API.new("comdlg32.dll", "GetOpenFileNameW", "p", "i")
  OFN_EXPLORER            = 0x00080000
  OFN_PATHMUSTEXIST       = 0x00000800
  OFN_FILEMUSTEXIST       = 0x00001000
  OFN_ALLOWMULTISELECT    = 0x00000200
  OFN_FLAGS = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST |
  OFN_ALLOWMULTISELECT
  #打开网页
  require 'win32ole'
  Shell = WIN32OLE.new('Shell.Application')
  
  module_function
  def get_open_file(title="选择文件", filter = {"所有文件 (*.*)" => "*.*"})
    szFile        = (0.chr * 20481).encode("UTF-16LE")
    szFileTitle   = 0.chr * 2049
    szTitle       = (title+"\0").encode("UTF-16LE")
    szFilter      = (filter.flatten.join("\0")+"\0\0").encode("UTF-16LE")
    szInitialDir  = "\0"
    
    ofn = 
      [
      76,                       # lStructSize       L
      0,                     # hwndOwner         L
      0,                        # hInstance         L
      szFilter,            # lpstrFilter       L
      0,                        # lpstrCustomFilter L
      0,                        # nMaxCustFilter    L
      1,                        # nFilterIndex      L
      szFile,              # lpstrFile         L
      szFile.size - 1,          # nMaxFile          L
      szFileTitle,         # lpstrFileTitle    L
      szFileTitle.size - 1,     # nMaxFileTitle     L
      szInitialDir,        # lpstrInitialDir   L
      szTitle,             # lpstrTitle        L
      OFN_FLAGS,                # Flags             L
      0,                        # nFileOffset       S
      0,                        # nFileExtension    S
      0,                        # lpstrDefExt       L
      0,                        # lCustData         L
      0,                        # lpfnHook          L
      0                         # lpTemplateName    L
    ].pack("LLLPLLLPLPLPPLS2L4")
    Dir.chdir{GetOpenFileName.call(ofn)}
    szFile.delete!("\0".encode("UTF-16LE"))
    szFile.encode("UTF-8")
  end
  def web(url)
    Shell.ShellExecute url
  end
  def uac(command, *args)
    Shell.ShellExecute File.expand_path(command), args.join(' '), Dir.pwd, "runas"
  end
end
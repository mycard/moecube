class Widget_InputBox
  require 'tk'
  @@root=TkRoot.new {
    withdraw
    overrideredirect true
    attributes :topmost, true
  }
  @@entry = TkEntry.new(@@root){
    takefocus 1
    validate :focusout
    validatecommand{@@root.withdraw;@@proc.call(get, false);true}
    bind('Key-Return'){@@root.withdraw;@@proc.call(get, true);true}
    pack
  }
  def self.show(x,y,text=nil, &proc)
    @@root.geometry "+#{x+TkWinfo.pointerx(@@root)-Mouse.state[0]}+#{y+TkWinfo.pointery(@@root)-Mouse.state[1]}"
    @@root.deiconify
    @@entry.text text if text
    @@proc = proc
    @@entry.focus :force
  end
  Thread.new{Tk.mainloop}
end

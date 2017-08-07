import * as child_process from 'child_process';
import {ChildProcess} from 'child_process';
import {app, BrowserWindow, Menu, shell, Tray} from 'electron';
import * as isDev from 'electron-is-dev';
import * as Store from 'electron-store';
import {autoUpdater} from 'electron-updater';
import * as net from 'net';
import {Socket} from 'net';
import {EOL} from 'os';
import * as path from 'path';
import * as readline from 'readline';
import {argv} from 'yargs';

class Main {

  static aria2: ChildProcess;
  static mainWindow: Electron.BrowserWindow | null;
  static updateWindow: Electron.BrowserWindow | null;
  static tray: Electron.Tray;
  static store = new Store();

  // 提权
  static handleElevate() {
    if (argv['e']) {
      if (process.platform === 'darwin') {
        app.dock.hide();
      }
      const elevate = JSON.parse(new Buffer(argv['e'], 'base64').toString());
      net.connect(elevate['ipc'], function (this: Socket) {
        process.send = (message, sendHandle) => this.write(JSON.stringify(message) + EOL);
        this.on('end', () => process.emit('disconnect', () => null));
        readline.createInterface({input: this}).on('line', (line) => process.emit('message', JSON.parse(line)));
        process.argv = elevate['arguments'][1];
        require('./' + elevate['arguments'][0]);
      });
      return true;
    }
  }

  static handleSingleInstance() {
    // Someone tried to run a second instance, we should focus our window.
    if (this.mainWindow) {
      if (this.mainWindow.isMinimized()) {
        this.mainWindow.restore();
      }
      if (!this.mainWindow.isVisible()) {
        this.mainWindow.show();
      }
      this.mainWindow.focus();
    }
  }

  static createAria2() {
    const aria2c = path.join(process.env['NODE_ENV'] === 'production' ? process.resourcesPath! : app.getAppPath(),
      'bin', process.platform === 'win32' ? 'aria2c.exe' : 'aria2c');
    return child_process.spawn(aria2c, [
      '--enable-rpc',
      '--rpc-allow-origin-all',
      '--continue',
      '--split=10',
      '--min-split-size=1M',
      '--max-connection-per-server=10',
      '--remove-control-file',
      '--allow-overwrite'
    ], {stdio: 'ignore'});
  }

  static createWindow() {
    // Create the browser window.
    this.mainWindow = new BrowserWindow({
      width: 1024,
      height: 640,
      minWidth: 1024,
      minHeight: 640,
      frame: process.platform === 'darwin',
      titleBarStyle: process.platform === 'darwin' ? 'hidden' : undefined,
      webPreferences: {
        webSecurity: false
      }
    });

    let locale = this.store.get('locale') || app.getLocale();
    locale = locale.startsWith('zh') ? 'zh-CN' : 'en-US';
    // and load the index.html of the app.

    this.mainWindow.loadURL(argv.url || `file://${__dirname}/index.html`);

    // Open the DevTools.
    if (isDev) {
      this.mainWindow.webContents.openDevTools();
    }

    // 在浏览器中打开新窗口
    this.mainWindow.webContents.on('new-window', function (event, url) {
      event.preventDefault();
      shell.openExternal(url);
    });

    // Emitted when the window is closed.
    this.mainWindow.on('closed', () => {
      // Dereference the window object, usually you would store windows
      // in an array if your app supports multi windows, this is the time
      // when you should delete the corresponding element.
      this.mainWindow = null;
    });
  }

  static createTray() {
    const icon = path.join(process.env['NODE_ENV'] === 'production' ? process.resourcesPath! : app.getAppPath(), 'assets', 'icon.ico');
    this.tray = new Tray(icon);
    this.tray.setToolTip('MoeCube');
    this.tray.setContextMenu(Menu.buildFromTemplate([
      {label: '显示主界面', type: 'normal', click: this.toggleMainWindow},
      {label: '退出', type: 'normal', click: app.quit}
    ]));
  }

  static toggleMainWindow() {
    if (this.mainWindow!.isVisible()) {
      this.mainWindow!.hide();
    } else {
      this.mainWindow!.show();
    }
  }

  static main() {

    if (this.handleElevate()) {
      return;
    }
    // 单例
    if (app.makeSingleInstance(this.handleSingleInstance)) {
      return;
    }
    // 调试模式
    if (!process.env['NODE_ENV']) {
      process.env['NODE_ENV'] = isDev ? 'development' : 'production';
    }

    this.aria2 = this.createAria2();

    global['autoUpdater'] = autoUpdater;
    autoUpdater.on('update-downloaded', () => {
      this.updateWindow = new BrowserWindow({width: 640, height: 360});
      this.updateWindow.loadURL(`file://${__dirname}/update/index.html`);
      this.updateWindow.on('closed', () => this.updateWindow = null);
    });

    app.on('ready', () => {
      this.createWindow();
      if (process.platform === 'win32') {
        this.createTray();
      }
      if (process.env['NODE_ENV'] === 'production') {
        autoUpdater.checkForUpdates();
      }
    });


    // Quit when all windows are closed.
    app.on('window-all-closed', () => {
      // On macOS it is common for applications and their menu bar
      // to stay active until the user quits explicitly with Cmd + Q
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', () => {
      // On macOS it's common to re-create a window in the app when the
      // dock icon is clicked and there are no other windows open.
      if (!this.mainWindow) {
        this.createWindow();
      }
    });

    app.on('quit', () => {
      // windows 在非 detach 模式下会自动退出子进程
      if (process.platform !== 'win32') {
        this.aria2.kill();
      }
    });
  }
}

Main.main();

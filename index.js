'use strict';

const { app, shell, BrowserWindow, Menu, Tray } = require('electron');
const { autoUpdater } = require('electron-updater');
const isDev = require('electron-is-dev');
const child_process = require('child_process');
const path = require('path');
const net = require('net');
const readline = require('readline');
const { EOL } = require('os');

// 提权
function handleElevate() {
  // for debug
  if (process.argv[1] === '.') {
    process.argv[1] = process.argv[2];
    process.argv[2] = process.argv[3];
  }

  if (process.argv[1] === '-e') {
    if (process.platform === 'darwin') {
      app.dock.hide();
    }
    let elevate = JSON.parse(new Buffer(process.argv[2], 'base64').toString());
    net.connect(elevate['ipc'], function () {
      process.send = (message, sendHandle, options, callback) => this.write(JSON.stringify(message) + EOL, callback);
      this.on('end', () => process.emit('disconnect'));
      readline.createInterface({ input: this }).on('line', (line) => process.emit('message', JSON.parse(line)));
      process.argv = elevate['arguments'][1];
      require('./' + elevate['arguments'][0]);
    });
    return true;
  }
}
if (handleElevate()) {
  return;
}

// 单例
const shouldQuit = app.makeSingleInstance(() => {
  // Someone tried to run a second instance, we should focus our window.
  if (mainWindow) {
    if (mainWindow.isMinimized()) {
      mainWindow.restore();
    }
    if (!mainWindow.isVisible()) {
      mainWindow.show();
    }
    mainWindow.focus();
  }
});
if (shouldQuit) {
  app.quit();
}

// 调试模式
if (!process.env['NODE_ENV']) {
  process.env['NODE_ENV'] = isDev ? 'development' : 'production';
}

// 自动更新
let updateWindow;
// 置 global 后可以在页面进程里取
global.autoUpdater = autoUpdater;
autoUpdater.on('update-downloaded', () => {
  updateWindow = new BrowserWindow({ width: 640, height: 360 });
  updateWindow.loadURL(`file://${__dirname}/update/index.html`);
  updateWindow.on('closed', () => updateWindow = null);
});

// Aria2c
const aria2 = (() => {
  let aria2c_path;
  switch (process.platform) {
    case 'win32':
      if (process.env['NODE_ENV'] === 'production') {
        aria2c_path = path.join(process.resourcesPath, 'bin', 'aria2c.exe');
      } else {
        aria2c_path = path.join('bin', 'aria2c.exe');
      }
      break;
    case 'darwin':
      if (process.env['NODE_ENV'] === 'production') {
        aria2c_path = path.join(process.resourcesPath, 'bin', 'aria2c');
      } else {
        aria2c_path = path.join('bin', 'aria2c');
      }
      break;
    default:
      throw 'unsupported platform';
  }
  return child_process.spawn(aria2c_path, ['--enable-rpc', '--rpc-allow-origin-all', '--continue', '--split=10', '--min-split-size=1M', '--max-connection-per-server=10', '--remove-control-file', '--allow-overwrite'], { stdio: 'ignore' });
})();

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 640,
    minWidth: 1024,
    minHeight: 640,
    frame: process.platform === 'darwin',
    titleBarStyle: process.platform === 'darwin' ? 'hidden' : null
  });

  // and load the index.html of the currentCube.
  mainWindow.loadURL(`file://${__dirname}/index.html`);

  // 在浏览器中打开新窗口
  mainWindow.webContents.on('new-window', function (event, url) {
    event.preventDefault();
    shell.openExternal(url);
  });

  // Open the DevTools.
  if (process.env['NODE_ENV'] === 'development') {
    mainWindow.webContents.openDevTools();
  }

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your currentCube supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null;
  });
}

function toggleMainWindow() {
  if (mainWindow.isVisible()) {
    mainWindow.hide();
  } else {
    mainWindow.show();
  }
}

// 托盘
let tray;
function createTray() {
  tray = new Tray(path.join(process.env['NODE_ENV'] === 'production' ? process.resourcesPath : app.getAppPath(), 'assets', 'icon.ico'));
  tray.on('click', () => event.metaKey ? mainWindow.webContents.openDevTools() : toggleMainWindow());
  tray.setToolTip('MoeCube');
  tray.setContextMenu(Menu.buildFromTemplate([
    { label: '显示主界面', type: 'normal', click: toggleMainWindow },
    { label: '退出', type: 'normal', click: app.quit }
  ]));
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', () => {
  createWindow();
  if (process.platform === 'win32') {
    createTray();
  }
  if (process.env['NODE_ENV'] === 'production') {
    autoUpdater.checkForUpdates();
  }
});

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', function (event) {
  // On OS X it's common to re-create a window in the currentCube when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow();
  }
});

// In this file you can include the rest of your currentCube's specific main process
// code. You can also put them in separate files and require them here.
app.on('quit', () => {
  // windows 在非 detach 模式下会自动退出子进程
  if (process.platform !== 'win32') {
    aria2.kill();
  }
});

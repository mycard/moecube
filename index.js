'use strict';

// 处理提权
function handleElevate() {
    // for debug
    if (process.argv[1] == '.') {
        process.argv[1] = process.argv[2];
        process.argv[2] = process.argv[3];
    }

    if (process.argv[1] == '-e') {
        if (process.platform == 'darwin') {
            require('electron').app.dock.hide();
        }
        let elevate = JSON.parse(new Buffer(process.argv[2], 'base64').toString());
        require('net').connect(elevate['ipc'], function () {
            process.send = (message, sendHandle, options, callback) => this.write(JSON.stringify(message) + require('os').EOL, callback);
            this.on('end', () => process.emit('disconnect'));
            require('readline').createInterface({input: this}).on('line', (line) => process.emit('message', JSON.parse(line)));
            process.argv = elevate['arguments'][1];
            require("./" + elevate['arguments'][0]);
        });
        return true;
    }
}
if (handleElevate()) {
    return;
}

const {ipcMain, app, shell, BrowserWindow, Menu, Tray} = require('electron');
const {autoUpdater} = require("electron-auto-updater");
const isDev = require('electron-is-dev');
const child_process = require('child_process');
const path = require('path');

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

// 单实例
const shouldQuit = app.makeSingleInstance((commandLine, workingDirectory) => {
    // Someone tried to run a second instance, we should focus our window.
    if (mainWindow) {
        if (mainWindow.isMinimized()) {
            mainWindow.restore()
        }
        if(!mainWindow.isVisible()){
            mainWindow.show();
        }
        mainWindow.focus()
    }
});
if (shouldQuit) {
    app.quit()
}

// 调试模式
if (!process.env['NODE_ENV']) {
    process.env['NODE_ENV'] = isDev ? 'development' : 'production'
}

// 自动更新
let updateWindow;
global.autoUpdater = autoUpdater;
if (process.env['NODE_ENV'] == 'production' && process.platform == 'darwin') {
    autoUpdater.setFeedURL("https://wudizhanche.mycard.moe/update/darwin/" + app.getVersion());
}
// else{
//     setTimeout(()=>{
//         autoUpdater.emit('checking-for-update')
//     }, 5000)
//     setTimeout(()=>{
//         autoUpdater.emit('error', '1')
//     }, 6000)
// }
autoUpdater.on('error', (event) => {
    global.update_status = 'error';
    console.log('autoUpdater', 'error', event);
});
autoUpdater.on('checking-for-update', () => {
    global.update_status = 'checking-for-update';
    console.log('autoUpdater', 'checking-for-update');
});
autoUpdater.on('update-available', () => {
    global.update_status = 'update-available';
    console.log('autoUpdater', 'update-available');
});
autoUpdater.on('update-not-available', () => {
    global.update_status = 'update-not-available';
    console.log('autoUpdater', 'update-not-available');
});
autoUpdater.on('update-downloaded', (event) => {
    global.update_status = 'update-downloaded';
    console.log('autoUpdater', 'update-downloaded', event);
    updateWindow = new BrowserWindow({
        width: 640,
        height: 480,
    });
    updateWindow.loadURL(`file://${__dirname}/update.html`);
    updateWindow.on('closed', function () {
        updateWindow = null
    });
    ipcMain.on('update', (event, arg) => {
        autoUpdater.quitAndInstall()
    })
});

// Aria2c
function createAria2c() {
    let aria2c_path;
    switch (process.platform) {
        case 'win32':
            if (process.env['NODE_ENV'] == 'production') {
                aria2c_path = path.join(process.resourcesPath, 'bin', 'aria2c.exe');
            } else {
                aria2c_path = path.join('bin', 'aria2c.exe');
            }
            break;
        case 'darwin':
            if (process.env['NODE_ENV'] == 'production') {
                aria2c_path = path.join(process.resourcesPath, 'bin', 'aria2c');
            } else {
                aria2c_path = path.join('bin', 'aria2c');
            }
            break;
        default:
            throw 'unsupported platform';
    }
    return child_process.spawn(aria2c_path, ['--enable-rpc', '--rpc-allow-origin-all', "--continue", "--split=10", "--min-split-size=1M", "--max-connection-per-server=10"], {stdio: 'ignore'});
}
const aria2c = createAria2c();

// 主窗口
function createWindow() {
    // Create the browser window.
    mainWindow = new BrowserWindow({
        width: 1024,
        height: 640,
        frame: process.platform == 'darwin',
        titleBarStyle: process.platform == 'darwin' ? 'hidden' : null
    });

    // and load the index.html of the app.
    mainWindow.loadURL(`file://${__dirname}/index.html`);

    mainWindow.webContents.on('new-window', function (e, url) {
        e.preventDefault();
        shell.openExternal(url);
    });

    // Open the DevTools.
    if (process.env['NODE_ENV'] == 'development') {
        mainWindow.webContents.openDevTools();
    }

    // Emitted when the window is closed.
    mainWindow.on('closed', function () {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        mainWindow = null
    })
}

function createTray() {
    console.log('create tray begin');
    let tray = new Tray(path.join(process.env['NODE_ENV'] == 'production' ? process.resourcesPath : app.getAppPath(), 'images', 'icon.ico'));
    tray.on('click', (event) => {
        mainWindow.isVisible() ? mainWindow.hide() : mainWindow.show();
    });
    const contextMenu = Menu.buildFromTemplate([
        // {label: '游戏', type: 'normal', click: (menuItem, browserWindow, event)=>{}},
        // {label: '社区', type: 'normal', click: (menuItem, browserWindow, event)=>{}},
        // {label: '切换账号', type: 'normal', click: (menuItem, browserWindow, event)=>{}},
        {
            label: '退出', type: 'normal', click: app.quit
        }
    ]);
    tray.setToolTip('MyCard');
    tray.setContextMenu(contextMenu);
    console.log('create tray finish');
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', () => {
    console.log('create window');
    createWindow();
    if (process.platform == 'win32') {
        console.log('before create tray');
        createTray()
    }
    if (process.env['NODE_ENV'] == 'production') {
        autoUpdater.checkForUpdates()
    }
    console.log('update');
});

// Quit when all windows are closed.
app.on('window-all-closed', function () {
    // On OS X it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    if (process.platform !== 'darwin') {
        app.quit()
    }
});

app.on('activate', function () {
    // On OS X it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (mainWindow === null) {
        createWindow()
    }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

app.on('quit', () => {
    // windows 在非 detach 模式下会自动退出子进程
    if (process.platform != 'win32') {
        aria2c.kill()
    }
});

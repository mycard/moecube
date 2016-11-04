'use strict';

const electron = require('electron');
const autoUpdater = require("electron-auto-updater").autoUpdater;

if (process.platform == 'darwin') {
    autoUpdater.setFeedURL("https://wudizhanche.mycard.moe/update");
}

autoUpdater.on('error', (event)=>console.log('error', event));
autoUpdater.on('checking-for-update', (event)=>console.log('checking-for-update', event));
autoUpdater.on('update-available', (event)=>console.log('update-available', event));
autoUpdater.on('update-not-available', (event)=>console.log('update-not-available', event));
autoUpdater.checkForUpdates();
console.log(1);

let updateWindow;
autoUpdater.on('update-downloaded', (event)=> {
    updateWindow = new BrowserWindow({
        width: 640,
        height: 480,
        // frame: process.platform == 'darwin',
        // titleBarStyle: process.platform == 'darwin' ? 'hidden' : null
    });

    // and load the index.html of the app.
    updateWindow.loadURL(`file://${__dirname}/update.html`);

    // Open the DevTools.
    // updateWindow.webContents.openDevTools();

    // Emitted when the window is closed.
    updateWindow.on('closed', function () {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        updateWindow = null
    })
});


const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

const child_process = require('child_process');
const path = require('path');

// this should be placed at top of main.js to handle setup events quickly
if (handleSquirrelEvent() || handleElevate()) {
    // squirrel event handled and app will exit in 1000ms, so don't do anything else
    return;
}

function handleSquirrelEvent() {
    if (process.argv.length === 1) {
        return false;
    }

    const ChildProcess = require('child_process');
    const path = require('path');

    const appFolder = path.resolve(process.execPath, '..');
    const rootAtomFolder = path.resolve(appFolder, '..');
    const updateDotExe = path.resolve(path.join(rootAtomFolder, 'Update.exe'));
    const exeName = path.basename(process.execPath);

    const spawn = function (command, args) {
        let spawnedProcess, error;

        try {
            spawnedProcess = ChildProcess.spawn(command, args, {detached: true});
        } catch (error) {
        }

        return spawnedProcess;
    };

    const spawnUpdate = function (args) {
        return spawn(updateDotExe, args);
    };

    const squirrelEvent = process.argv[1];
    switch (squirrelEvent) {
        case '--squirrel-install':
        case '--squirrel-updated':
            // Optionally do things such as:
            // - Add your .exe to the PATH
            // - Write to the registry for things like file associations and
            //   explorer context menus

            // Install desktop and start menu shortcuts
            spawnUpdate(['--createShortcut', exeName]);

            setTimeout(app.quit, 1000);
            return true;

        case '--squirrel-uninstall':
            // Undo anything you did in the --squirrel-install and
            // --squirrel-updated handlers

            // Remove desktop and start menu shortcuts
            spawnUpdate(['--removeShortcut', exeName]);

            setTimeout(app.quit, 1000);
            return true;

        case '--squirrel-obsolete':
            // This is called on the outgoing version of your app before
            // we update to the new version - it's the opposite of
            // --squirrel-updated

            app.quit();
            return true;
    }
}
function handleElevate() {
    if (process.argv[1] == '-e') {
        app.dock.hide();
        const os = require('os');
        const readline = require('readline');
        process.send = (message, sendHandle, options, callback)=> process.stdout.write(JSON.stringify(message) + os.EOL, callback);
        process.stdin.on('end', ()=> process.emit('disconnect'));
        readline.createInterface({input: process.stdin}).on('line', (line) => process.emit('message', JSON.parse(line)));
        require("./" + process.argv[2]);
        return true;
    }
}

function createAria2c() {
    let aria2c_path;
    switch (process.platform) {
        case 'win32':
            aria2c_path = path.join(process.execPath, '..', '..', 'aria2c.exe');
            break;
        case 'darwin':
            aria2c_path = 'aria2c'; // for debug
            break;
        default:
            throw 'unsupported platform';
    }
    //--split=10 --min-split-size=1M --max-connection-per-server=10
    let aria2c = child_process.spawn(aria2c_path,
        ['--enable-rpc', '--rpc-allow-origin-all', "--continue", "--split=10", "--min-split-size=1M", "--max-connection-per-server=10"],
        {stdio: 'ignore'});
    aria2c.on('data', (data)=> {
        console.log(data);
    });
    return aria2c;
}

const aria2c = createAria2c();

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

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

    // Open the DevTools.
    mainWindow.webContents.openDevTools();

    // Emitted when the window is closed.
    mainWindow.on('closed', function () {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        mainWindow = null
    })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow);

// Quit when all windows are closed.
app.on('window-all-closed', function () {
    app.quit()
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

app.on('quit', ()=> {
    // windows 在非 detach 模式下会自动退出子进程
    if (process.platform != 'win32') {
        aria2c.kill()
    }
});
'use strict';

const electron = require('electron');
const app = electron.app;  // Module to control application life.
const BrowserWindow = electron.BrowserWindow;  // Module to create native browser window.

let handleStartupEvent = function () {
    if (process.platform !== 'win32') {
        return false;
    }

    let squirrelCommand = process.argv[1];
    switch (squirrelCommand) {
        case '--squirrel-install':
        case '--squirrel-updated':

            // Optionally do things such as:
            //
            // - Install desktop and start menu shortcuts
            // - Add your .exe to the PATH
            // - Write to the registry for things like file associations and
            //   explorer context menus

            // Always quit when done

            const path = require('path');
            const reg = require('winreg');
            const shortcuts = require('windows-shortcuts');

            let pending = 7;
            let done = ()=> {
                pending--;
                if (pending == 0) {
                    app.quit()
                }
            };

            shortcuts.create(path.join(app.getPath('desktop'), 'MyCard.lnk'), process.execPath, done);
            let key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\mycard'});
            key.set('URL Protocol', reg.REG_SZ, '"' + process.execPath + '"', done);
            key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\mycard\\shell\\open\\command'});
            key.set('', reg.REG_SZ, '"' + process.execPath + '" "%i"', done);
            key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\mycard\\DefaultIcon'});
            key.set('', reg.REG_SZ, '"' + process.execPath + '", 0', done);
            key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\.ydk'});
            key.set('', reg.REG_SZ, 'mycard', done);
            key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\.ydk'});
            key.set('', reg.REG_SZ, 'mycard', done);
            key = new reg({hive: reg.HKCU, key: '\\Software\\Classes\\.deck'});
            key.set('', reg.REG_SZ, 'mycard', done);

            return true;
        case '--squirrel-uninstall':
            // Undo anything you did in the --squirrel-install and
            // --squirrel-updated handlers

            // Always quit when done
            app.quit();

            return true;
        case '--squirrel-obsolete':
            // This is called on the outgoing version of your app before
            // we update to the new version - it's the opposite of
            // --squirrel-updated
            app.quit();
            return true;
    }
};

if (handleStartupEvent()) {
    return;
}

let shouldQuit = app.makeSingleInstance(function (commandLine, workingDirectory) {
    // Someone tried to run a second instance, we should focus our window.
    if (mainWindow) {
        if (mainWindow.isMinimized()) mainWindow.restore();
        mainWindow.focus();
    }
    return true;
});

if (shouldQuit) {
    app.quit();
}


// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow = null;

// Quit when all windows are closed.
app.on('window-all-closed', function () {
    // On OS X it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    //if (process.platform != 'darwin') {
    app.quit();
    //}
});

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', function () {
    // Create the browser window.
    mainWindow = new BrowserWindow({
        width: 1024,
        height: 640,
        frame: process.platform == 'darwin',
        'title-bar-style': process.platform == 'darwin' ? 'hidden-inset' : null,
    });

    // and load the index.html of the app.
    //mainWindow.loadURL('http://local.mycard.moe:3000');
    mainWindow.loadURL('file://' + __dirname + '/index.html#ygopro');

    //debug
    let dev = false;
    let local = false;
    for (let arg of process.argv) {
        switch (arg) {
            case '--dev':
                dev = true;
                break;
            case '--local':
                local = true;
                break;
        }
    }
    if (local || dev) {
        // Open the DevTools.
        mainWindow.webContents.on('dom-ready', ()=> {
            if (local) {
                mainWindow.webContents.executeJavaScript(`
                    let webview = document.getElementById('ygopro');
                    webview.src = 'http://local.mycard.moe:3000/'
                `)
            }
            if (dev) {
                mainWindow.webContents.openDevTools();
                mainWindow.webContents.executeJavaScript(`
                    let webview = document.getElementById('ygopro');
                    webview.addEventListener("dom-ready", function() {
                        webview.openDevTools();
                    })
                `)
            }
        })
    }


    // Emitted when the window is closed.
    mainWindow.on('closed', function () {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        mainWindow = null;
    });

    //debug
    /*<webview id="ygopro" src="http://local.mycard.moe:3000/"></webview>
     let webview = document.getElementById(hash);
     webview.addEventListener("dom-ready", function () {
     webview.openDevTools();
     });*/
});

//const ipcMain = require('electron').ipcMain;
const ygopro = require('./apps');
/*ipcMain.on('join', (event, args) => {
 ygopro.emit('run', args);
 });

 ygopro.on('run', (args) => {

 });*/
/*
 autoUpdater.setFeedUrl('http://localhost:4001?version=' + app.getVersion());
 autoUpdater.checkForUpdates();
 autoUpdater
 .on('checking-for-update', function () {
 console.log('Checking for update');
 })
 .on('update-available', function () {
 console.log('Update available');
 })
 .on('update-not-available', function () {
 console.log('Update not available');
 })
 .on('update-downloaded', function () {
 console.log('Update downloaded');
 });*/
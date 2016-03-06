'use strict';

const fs = require('fs');
const path = require('path');
const child_process = require('child_process');
const querystring = require('querystring');

const ini = require('ini');
const glob = require("glob");
const mkdirp = require('mkdirp');

const Aria2 = require('aria2');

const EventEmitter = require('events');
const eventemitter = new EventEmitter();

const autoUpdater = require('auto-updater');
const electron = require('electron');
const ipcMain = electron.ipcMain;
const app = electron.app;
const shell = electron.shell;
const BrowserWindow = electron.BrowserWindow;

const watcher = {};

const data_path = app.getPath('userData');
const db_path = path.join(data_path, 'db.json');

const db = {apps: {}, local: {}};
try {
    Object.assign(db, require(db_path));
} catch (error) {
}

db.version = app.getVersion();
db.platform = process.platform;
db.default_apps_path = path.join(data_path, 'apps');

let bundle;
try {
    bundle = require('./bundle.json')
} catch (error) {
}

function save_db() {
    fs.writeFile(db_path, JSON.stringify(db));
}

eventemitter.on('install', (app, options) => {
    if (db.local[app.id]) return;

    db.apps[app.id] = app;

    let local = db.local[app.id] = {
        status: 'installing'
    };

    if (options.path) {
        local.path = options.path;
    } else {
        local.path = path.join(db.default_apps_path, app.id);
    }

    eventemitter.emit('update', app, local, 'install-started');
    mkdirp(local.path, ()=> {
        let options = {
            stdio: 'inherit',
            cwd: __dirname
        };
        if (db.platform == 'win32') {
            options.env = {PATH: path.join(__dirname, 'bin')}
        }
        console.log(options);
        let tar = child_process.spawn('tar', ['fx', app.id + '.tar.xz', '-C', local.path], options);
        console.log(tar);
        tar.on('exit', (code) => {
            console.log(code)
            if (code == 0) {

                load(app, local, ()=> {
                    local.status = 'ready';
                    eventemitter.emit('update', app, local, 'install-successful');
                });

            } else {
                delete db.local[app.id];
                eventemitter.emit('update', app, local, 'install-failed');
                eventemitter.emit('update', app, null);
            }
        });
    })
});

let running = [];
eventemitter.on('action', function (app_id, action, options) {
    let local = db.local[app_id];
    Object.assign(local.files['system.conf'].content, options);
    fs.writeFile(path.join(local.path, 'system.conf'), ini.stringify(local.files['system.conf'].content, {whitespace: true}), (error)=> {
        if (error) return console.log(error);
        for (let window of BrowserWindow.getAllWindows()) {
            window.minimize()
        }
        let args = {'join': '-j', 'deck': '-d'}[action];
        let main;
        if (process.platform == 'darwin') {
            main = 'ygopro.app/Contents/MacOS/ygopro'
        } else {
            main = 'ygopro_vs.exe'
        }

        let child = child_process.spawn(main, [args], {cwd: local.path, stdio: 'inherit'});
        running.push(child);
        child.on('exit', ()=> {
            running.splice(running.indexOf(child), 1);
            if (running.length == 0) {
                for (let window of BrowserWindow.getAllWindows()) {
                    window.restore()
                }
            }
        })
    })
});

eventemitter.on('delete', (app_id, file) => {
    fs.unlink(path.join(db.local[app_id].path, file));
    delete db.local[app_id].files[file];
});

eventemitter.on('explore', (app_id) => {
    electron.shell.showItemInFolder(path.join(db.local[app_id].path, 'deck'))
});

eventemitter.on('write', (app_id, file, data, merge) => {
    let local = db.local[app_id];
    if (file == 'system.conf') {
        if (merge) {
            Object.assign(local.files[file].content, data)
        } else {
            local.files[file].content = data
        }
        fs.writeFile(path.join(local.path, file), ini.stringify(local.files[file].content, {whitespace: true}))
    }
    //TODO: others
});

//fixme: refactoring

let pending = 1;
for (let app_id in db.local) {
    if (db.local[app_id].status == 'installing') {
        let options = db.local[app_id];
        delete db.local[app_id];
        eventemitter.emit('install', db.apps[app_id], options);
    } else {
        db.local[app_id].status = 'ready';
        pending++;
        load(db.apps[app_id], db.local[app_id], done);
    }
}

child_process.spawn(path.join(__dirname, 'bin', 'aria2c'), ['--enable-rpc', '--rpc-allow-origin-all']);

done();

function done() {
    pending--;
    if (pending == 0) {
        start_server();
    }
}

function start_server() {
    const WebSocketServer = require('ws').Server;
    const server = new WebSocketServer({host: '127.0.0.1', port: 9999});

    server.on('connection', (connection) => {
        connection.send(JSON.stringify({
            event: 'init',
            data: [db]
        }));

        if (bundle && Object.keys(db.local).length == 0) {
            connection.send(JSON.stringify({
                event: 'bundle',
                data: [bundle]
            }));
        }
        connection.on('message', (message) => {
            message = JSON.parse(message);
            if (message.event == 'login') {
                let user = message.data[0];
                for (let window of BrowserWindow.getAllWindows()) {
                    window.webContents.send('login', user);
                }
                message = JSON.stringify({event: 'login', data: [user]});
                for (let client of server.clients) {
                    if (client != connection) {
                        try {
                            client.send(message);
                        } catch (error) {
                        }
                    }
                }
            } else {
                eventemitter.emit(message.event, ...message.data);
            }

        });
    });
    eventemitter.on('update', (app, local, resson)=> {
        let message = JSON.stringify({event: 'update', data: [app, local, resson]});
        for (let connection of server.clients) {
            connection.send(message);
        }
        save_db();
    });

    const platform = {win32: 'win'}[process.platform] + {
            ia32: '32',
            x64: '64'
        }[process.arch];

    if (process.platform == 'win32' && db.local['ygopro'] && db.local['ygopro'].status == 'ready') {
        autoUpdater.setFeedURL('https://mycard.moe/update/' + platform);
        if (process.argv[1] == '--squirrel-firstrun') {
            setTimeout(()=> {
                autoUpdater.checkForUpdates();
            }, 10000)
        } else {
            autoUpdater.checkForUpdates();
        }

        /*autoUpdater.on('error', (error)=>{
         console.log('update error', error)
         });
         autoUpdater.on('checking-for-update', ()=>{
         console.log('checking-for-update')
         });
         autoUpdater.on('update-available', ()=>{
         console.log('update-available')
         });*/
        autoUpdater.on('update-not-available', ()=> {
            // check for ygopro update
            const aria2 = new Aria2();
            //debug
            aria2.onsend = function (m) {
                console.log('aria2 OUT', m);
            };
            aria2.onmessage = function (m) {
                console.log('aria2 IN', m);
            };
            let params = {platform: platform};
            params.ygopro = db.apps.ygopro.version;
            let meta = {};
            let update_count = 0;
            let pending_install = [];
            let download_dir = app.getPath('temp');
            aria2.open(()=> {
                console.log('checking apps update');
                aria2.addUri(['https://mycard.moe/apps.meta4?' + querystring.stringify(params)], {'dir': download_dir}, (error, gid)=> {
                    meta = gid
                })
            });
            /*aria2.onDownloadStart = function (response) {
             aria2.getFiles(response.gid, (error, response)=> {
             console.log('start', error, JSON.stringify(response))
             })
             };*/
            aria2.onDownloadComplete = function (response) {
                aria2.tellStatus(response.gid, (error, response)=> {
                    if (meta == response.gid) {
                        if (response.followedBy) {
                            update_count = response.followedBy.length;
                        }
                    } else {
                        console.log('download complete', response.files);
                        pending_install.push(path.basename(response.files[0].path));
                        if (pending_install.length == update_count) {
                            for (let child of running) {
                                child.kill()
                            }
                            let app = db.apps.ygopro; //hacky
                            let local = db.local.ygopro;

                            local.status = 'updating';
                            eventemitter.emit('update', app, local, 'update');

                            pending_install.sort();
                            (function extract() {
                                let file = pending_install.shift();
                                console.log(file);
                                if (file) {
                                    let options = {
                                        stdio: 'inherit',
                                        cwd: download_dir
                                    };
                                    if (db.platform == 'win32') {
                                        options.env = {PATH: path.join(__dirname, 'bin')}
                                    }
                                    console.log(options);
                                    let tar = child_process.spawn('tar', ['fx', file, '-C', local.path], options);
                                    tar.on('exit', (code) => {
                                        if (code == 0) {
                                            let matched = file.match(/ygopro-update-win32-(.+)\.tar\.xz/);
                                            if (matched) {
                                                app.version = matched[1];
                                                save_db();
                                            }
                                            extract()
                                        } else {
                                            load(app, local, ()=> {
                                                local.status = 'ready';
                                                eventemitter.emit('update', app, local, 'update-failed');
                                            });
                                        }
                                    });

                                } else {
                                    load(app, local, ()=> {
                                        local.status = 'ready';
                                        eventemitter.emit('update', app, local, 'update-successful');
                                    });
                                }
                            })();
                        }
                    }
                })
            };
            aria2.onDownloadError = function (response) {
                let app = db.apps.ygopro; //hacky
                let local = db.local.ygopro;
                eventemitter.emit('update', app, local, 'update-failed');
                /*aria2.tellStatus(response.gid, (error, response)=> {
                 console.log('onDownloadComplete', error, JSON.stringify(response))
                 })*/
            };

        });
        autoUpdater.on('update-downloaded', ()=> {
            autoUpdater.quitAndInstall()
        })
    }
}

function load(app, local, callback) {
    let pending = 1;
    let done = ()=> {
        pending--;
        //console.log(pending);
        if (pending == 0) {
            callback();
        }
    };
    if (app.files) {
        local.files = {};
        for (let pattern in app.files) {
            pending++;
            glob(pattern, {cwd: local.path}, (error, files)=> {
                if (error)return done();
                for (let file of files) {
                    if (app.files[pattern].content == 'ini') {
                        pending++;
                        //console.log('ini pending');
                        fs.readFile(path.join(local.path, file), 'utf8', (error, content)=> {
                            if (error)return done();
                            local.files[file] = {content: ini.parse(content)} || {};
                            if (file == 'system.conf') {
                                pending += 2;
                                //console.log('fonts pending + 2');
                                let textfonts;
                                switch (process.platform) {
                                    case 'darwin':
                                        textfonts = ['/System/Library/Fonts/PingFang.ttc'];
                                        break;
                                    case 'win32':
                                        textfonts = [path.join(process.env.SystemRoot, 'fonts/msyh.ttc'), path.join(process.env.SystemRoot, 'fonts/msyh.ttf'), path.join(process.env.SystemRoot, 'fonts/simsun.ttc')]
                                        break;
                                }
                                let origin = [];
                                if (local.files[file] && local.files[file].content && local.files[file].content.textfont) {
                                    origin.push(path.resolve(local.path, local.files[file].content.textfont.split(' ')[0]))
                                }
                                first_exists(origin.concat(textfonts), (textfont)=> {
                                    if (textfont) {
                                        local.files[file].content.textfont = path.relative(local.path, textfont) + ' 14';
                                    }
                                    //console.log('textfonts done');
                                    done()
                                });
                                let numfonts;
                                switch (process.platform) {
                                    case 'darwin':
                                        numfonts = ['/System/Library/Fonts/HelveticaNeue.dfont'];
                                        break;
                                    case 'win32':
                                        numfonts = [path.join(process.env.SystemRoot, 'fonts/arialbd.ttf')];
                                        break;
                                }
                                first_exists([path.resolve(local.path, local.files[file].content.numfont)].concat(numfonts), (numfont)=> {
                                    if (numfont) {
                                        local.files[file].content.numfont = path.relative(local.path, numfont);
                                    }
                                    //console.log('numfonts done');
                                    done()
                                });
                            }
                            done()
                        })
                    }
                    else {
                        local.files[file] = {};
                    }

                }
                done()
            })
        }
    }

    if (!watcher[app.id]) {
        fs.watch(db.local[app.id].path, {recursive: true}, (event, filename)=> {
            load(db.apps[app.id], db.local[app.id], ()=> {
                eventemitter.emit('update', app, local, event)
            });
        });
        watcher[app.id] = true;
    }
    done()
}

function first_exists(files, callback, index) {
    if (!index) index = 0;
    if (index >= files.length) return callback();
    let file = files[index];
    fs.access(file, (error)=> {
        if (error) {
            first_exists(files, callback, index + 1);
        } else {
            callback(file)
        }
    })
}
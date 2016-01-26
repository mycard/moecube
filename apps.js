'use strict';

const os = require('os');
const fs = require('fs');
const path = require('path');
const child_process = require('child_process');

const ini = require('ini');
const glob = require("glob");
const mkdirp = require('mkdirp');

const EventEmitter = require('events');
const eventemitter = new EventEmitter();

const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

const data_path = app.getPath('userData');
const db_path = path.join(data_path, 'db.json');

const db = {apps: {}, local: {}};
try {
    Object.assign(db, require(db_path));
} catch (error) {
}

db.version = app.getVersion();
db.platform = os.platform();
db.default_apps_path = path.join(data_path, 'apps');

var bundle;
try {
    bundle = require('./bundle.json')
} catch (error) {
}

function save_db() {
    fs.writeFile(db_path, JSON.stringify(db));
}

eventemitter.on('install', (app, options) => {
    console.log(app, options);
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
        let extract = child_process.spawn('tar', ['fx', app.id + '.tar.xz', '-C', local.path], {stdio: 'inherit'});
        extract.on('exit', (code) => {
            console.log(code);
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

eventemitter.on('action', function (app_id, action, options) {
    var local = db.local[app_id];
    Object.assign(local.files['system.conf'].content, options);
    fs.writeFile(path.join(local.path, 'system.conf'), ini.stringify(local.files['system.conf'].content, {whitespace: true}), (error)=> {
        if (error) return console.log(error);
        for (let window of BrowserWindow.getAllWindows()) {
            window.minimize()
        }
        let args = {'join': '-j', 'deck': '-d'}[action];
        let main;
        if (os.platform() == 'darwin') {
            main = 'ygopro.app/Contents/MacOS/ygopro'
        } else {
            main = 'ygopro_vs.exe'
        }
        console.log(main, [args], {cwd: local.path});

        let child = child_process.spawn(main, [args], {cwd: local.path, stdio: 'inherit'});
        child.on('exit', ()=> {
            for (let window of BrowserWindow.getAllWindows()) {
                window.restore()
            }
        })
    })
});

eventemitter.on('delete', (app_id, file) => {
    fs.unlink(path.join(db.local[app_id].path, file));
    delete db.local[app_id].files[file];
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
    pending++;
    load(db.apps[app_id], db.local[app_id], done);
}
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

        if (bundle && Object.keys(db.apps).length == 0) {
            connection.send(JSON.stringify({
                event: 'bundle',
                data: [bundle]
            }));
        }
        connection.on('message', (message) => {
            message = JSON.parse(message);
            eventemitter.emit(message.event, ...message.data);
        });
    });

    eventemitter.on('update', (app, local, resson)=> {
        let message = JSON.stringify({event: 'update', data: [app, local, resson]});
        for (let connection of server.clients) {
            connection.send(message);
        }
        save_db();
    })
}


function load(app, local, callback) {
    let pending = 1;
    let done = ()=> {
        pending--;
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
                        fs.readFile(path.join(local.path, file), 'utf8', (error, content)=> {
                            if (error)return done();
                            local.files[file] = {content: ini.parse(content)};
                            done()
                        })
                    } else {
                        local.files[file] = {};
                        done()
                    }

                }
            })
        }
    }
    done()
}

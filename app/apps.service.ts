import {Injectable, ApplicationRef} from "@angular/core";
import {Http} from "@angular/http";
import {App, AppStatus, Action} from "./app";
import {SettingsService} from "./settings.sevices";
import * as fs from "fs";
import * as path from "path";
import * as child_process from "child_process";
import {remote} from "electron";
import "rxjs/Rx";
import {AppLocal} from "./app-local";
import * as ini from "ini";

const Aria2 = require('aria2');
const sudo = require('electron-sudo');

interface Connection {
    connection: WebSocket, address: string | null
}

@Injectable()
export class AppsService {

    private apps: Map<string,App>;

    constructor(private http: Http, private settingsService: SettingsService, private ref: ApplicationRef,) {
    }


    loadApps() {
        return this.http.get('./apps.json')
            .toPromise()
            .then((response) => {
                let data = response.json();
                this.apps = this.loadAppsList(data);
                return this.apps;
            });
    }

    loadAppsList = (data: any): Map<string,App> => {
        let apps = new Map<string,App>();
        let locale = this.settingsService.getLocale();
        let platform = process.platform;

        for (let item of data) {
            let app = new App(item);
            let local = localStorage.getItem(app.id);
            if (local) {
                app.local = new AppLocal();
                app.local.update(JSON.parse(local));
            }
            app.status = new AppStatus();
            if (local) {
                app.status.status = "ready";
            } else {
                app.status.status = "init";
            }

            // 去除无关语言
            ['name', 'description'].forEach((key) => {
                let value = app[key][locale];
                if (!value) {
                    value = app[key]["en-US"];
                }
                app[key] = value;
            });

            // 去除平台无关的内容
            ['actions', 'dependencies', 'references', 'download', 'version'].forEach((key) => {
                if (app[key]) {
                    if (app[key][platform]) {
                        app[key] = app[key][platform];
                    }
                    else {
                        app[key] = null;
                    }
                }
            });
            apps.set(item.id, app);

        }

        // 设置App关系
        for (let [id] of apps) {
            let temp = (<App>apps.get(id))["actions"];
            let map = new Map<string,any>();
            for (let action of Object.keys(temp)) {
                let openId = temp[action]["open"];
                if (openId) {
                    temp[action]["open"] = apps.get(openId);
                }
                map.set(action, temp[action]);
            }
            (<App>apps.get(id)).actions = map;

            ['dependencies', 'references', 'parent'].forEach((key) => {
                let app = <App>apps.get(id);
                let value = app[key];
                if (value) {
                    if (Array.isArray(value)) {
                        let map = new Map<string,App>();
                        value.forEach((appId, index, array) => {
                            map.set(appId, apps.get(appId));
                        });
                        app[key] = map;
                    } else {
                        app[key] = apps.get(value);
                    }
                }
            });
        }
        return apps;
    };

    findChildren(app: App): App[] {
        let children: App[] = [];
        for (let [id,child] of this.apps) {
            if (child.parent === app) {
                children.push(child);
            }
        }
        return children;
    }

    async runApp(app: App) {
        let children = this.findChildren(app);
        let cwd = (<AppLocal>app.local).path;
        let action: Action = <Action>app.actions.get('main');
        let args: string[] = [];
        let env = {};
        for (let child of children) {
            if (child.isInstalled()) {
                let _action = child.actions.get('main');
                if (_action) {
                    action = _action
                }
            }
        }
        let execute = path.join(cwd, action.execute);
        if (action.open) {
            if (action.open.id == 'np2fmgen') {
                const config_file = path.join((<AppLocal>(<App>action.open).local).path, 'np21nt.ini');
                let config = await new Promise((resolve, reject) => {
                    let config = fs.readFile(config_file, {encoding: 'utf-8'}, (error, data) => {
                        if (error) return reject(error);
                        resolve(ini.parse(data));
                    });

                });
                config['NekoProject21']['HDD1FILE'] = path.win32.join((<AppLocal>app.local).path, action.execute);
                await new Promise((resolve, reject) => {
                    fs.writeFile(config_file, ini.stringify(config), (error) => {
                        if (error) {
                            reject(error)
                        } else {
                            resolve()
                        }
                    })
                });
            }
            let openAction = <Action>action.open.actions.get('main');
            args = args.concat(openAction.args);
            args.push(action.execute);
            execute = path.join((<AppLocal>action.open.local).path, openAction.execute);
            env = Object.assign(env, openAction.env);
        }
        args = args.concat(action.args);
        env = Object.assign(env, action.env);
        console.log(execute, args, env, cwd);
        let handle = child_process.spawn(execute, args, {env: env, cwd: cwd});

        handle.stdout.on('data', (data) => {
            console.log(`stdout: ${data}`);
        });

        handle.stderr.on('data', (data) => {
            console.log(`stderr: ${data}`);
        });

        handle.on('close', (code) => {
            console.log(`child process exited with code ${code}`);
            remote.getCurrentWindow().restore();
        });

        remote.getCurrentWindow().minimize();
    }

    browse(app: App) {
        remote.shell.showItemInFolder((<AppLocal>app.local).path);
    }

    connections = new Map<App, Connection>();
    maotama;

    async network(app: App, server) {
        if (!this.maotama) {
            this.maotama = new Promise((resolve, reject) => {
                let child = sudo.fork('maotama', [], {stdio: ['inherit', 'inherit', 'inherit', 'ipc']});
                child.once('message', () => resolve(child));
                child.once('error', reject);
                child.once('exit', reject);
            })
        }
        let child;
        try {
            child = await this.maotama;
        } catch (error) {
            alert(`出错了 ${error}`);
            return
        }

        let connection: Connection | undefined = this.connections.get(app);
        if (connection) {
            connection.connection.close();
        }
        connection = {connection: new WebSocket(server.url), address: null};
        let id;
        this.connections.set(app, connection);
        connection.connection.onmessage = (event) => {
            console.log(event.data);
            let [action, args] = event.data.split(' ', 2);
            let [address, port] = args.split(':');
            switch (action) {
                case 'LISTEN':
                    (<Connection>connection).address = args;
                    this.ref.tick();
                    break;
                case 'CONNECT':
                    id = setInterval(() => {
                        child.send({
                            action: 'connect',
                            arguments: [app.network.port, port, address]
                        })
                    }, 200);
                    break;
                case 'CONNECTED':
                    clearInterval(id);
                    id = null;
                    break;
            }
        };
        connection.connection.onclose = (event: CloseEvent) => {
            if (id) {
                clearInterval(id);
            }
            // 如果还是在界面上显示的那个连接
            if (this.connections.get(app) == connection) {
                this.connections.delete(app);
                if (event.code != 1000 && !(<Connection>connection).address) {
                    alert(`出错了 ${event.code}`);
                }
            }
            // 如果还没建立好就出错了，就弹窗提示这个错误
            this.ref.tick();
        };
    }
}
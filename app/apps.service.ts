import {Injectable, ApplicationRef, NgZone} from "@angular/core";
import {Http} from "@angular/http";
import {App, AppStatus} from "./app";
import {InstallConfig} from "./install-config";
import {SettingsService} from "./settings.sevices";
import * as os from "os";
import * as fs from "fs";
import * as path from "path";
import * as readline from "readline";
import * as mkdirp from "mkdirp";
import * as child_process from "child_process";
import {remote} from "electron";
import "rxjs/Rx";
import {AppLocal} from "./app-local";


const Aria2 = require('aria2');
const Sudo = require('electron-sudo').default;

Sudo.prototype.fork = async function (modulePath, args, options) {
    let child = await this.spawn(remote.app.getPath('exe'), ['-e', modulePath].concat(args), options);
    readline.createInterface({input: child.stdout}).on('line', (line) => {
        child.emit('message', JSON.parse(line));
    });
    child.send = (message, sendHandle, options, callback)=> {
        child.stdin.write(JSON.stringify(message) + os.EOL);
        if (callback) {
            callback()
        }
    };
    return child
};

@Injectable()
export class AppsService {

    constructor(private http: Http, private settingsService: SettingsService, private ref: ApplicationRef, private ngZong: NgZone) {
    }


    loadApps() {
        return this.http.get('./apps.json')
            .toPromise()
            .then((response)=> {
                let data = response.json();
                return this.loadAppsList(data);
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
            ['name', 'description'].forEach((key)=> {
                let value = app[key][locale];
                if (!value) {
                    value = app[key]["en-US"];
                }
                app[key] = value;
            });

            // 去除平台无关的内容
            ['actions', 'dependencies', 'references', 'download', 'version'].forEach((key)=> {
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
        for (let id of Array.from(apps.keys())) {
            let temp = apps.get(id)["actions"];
            let map = new Map<string,any>();
            for (let action of Object.keys(temp)) {
                let openId = temp[action]["open"];
                if (openId) {
                    temp[action]["open"] = apps.get(openId);
                }
                map.set(action, temp[action]);
            }
            apps.get(id).actions = map;

            ['dependencies', 'references', 'parent'].forEach((key)=> {
                let app = apps.get(id);
                let value = app[key];
                if (value) {
                    if (Array.isArray(value)) {
                        let map = new Map<string,App>();
                        value.forEach((appId, index, array)=> {
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


    deleteFile(path: string): Promise<string> {
        return new Promise((resolve, reject)=> {
            fs.lstat(path, (err, stats)=> {
                if (err) return resolve(path);
                if (stats.isDirectory()) {
                    fs.rmdir(path, (err)=> {
                        resolve(path);
                    });
                } else {
                    fs.unlink(path, (err)=> {
                        resolve(path);
                    });
                }
            });
        })
    }

    saveAppLocal(app: App, appLocal: AppLocal) {
        localStorage.setItem(app.id, JSON.stringify(appLocal));
    }

    install(config: InstallConfig) {
        let app = config.app;
    }

    uninstall(id: string) {
        // //let current = this;
        // if (this.checkInstall(id)) {
        //     let files: string[] = this.searchApp(id).local.files.sort().reverse();
        //     // 删除本目录
        //     files.push('.');
        //     let install_dir = this.searchApp(id).local.path;
        //     return files
        //         .map((file)=>
        //             ()=>path.join(install_dir, file)
        //         )
        //         .reduce((promise: Promise<string>, task)=>
        //                 promise.then(task).then(this.deleteFile)
        //             , Promise.resolve(''))
        //         .then((value)=> {
        //             this.searchApp(id).local = null;
        //             localStorage.setItem("localAppData", JSON.stringify(this.data));
        //             return Promise.resolve()
        //         });
        // }

    }


    browse(app: App) {
        remote.shell.showItemInFolder(app.local.path);
    }

    connections = new Map<App, {connection: WebSocket, address: string}>();
    maotama;

    async network(app: App, server) {
        if (!this.maotama) {
            this.maotama = new Sudo({name: 'MyCard'}).fork('maotama')
        }
        let child = await this.maotama;
        // child.on('message', console.log);
        // child.on('exit', console.log);
        // child.on('error', console.log);

        let connection = this.connections.get(app);
        if (connection) {
            connection.connection.close();
        }
        connection = {connection: new WebSocket(server.url), address: null};
        let id;
        this.connections.set(app, connection);
        connection.connection.onmessage = (event)=> {
            console.log(event.data);
            let [action, args] = event.data.split(' ', 2);
            let [address, port] = args.split(':');
            switch (action) {
                case 'LISTEN':
                    connection.address = args;
                    this.ref.tick();
                    break;
                case 'CONNECT':
                    this.ngZong.runOutsideAngular(()=> {
                        id = setInterval(()=> {
                            child.send({
                                action: 'connect',
                                arguments: [app.network.port, port, address]
                            })
                        }, 200);
                    });
                    break;
                case 'CONNECTED':
                    clearInterval(id);
                    id = null;
                    break;
            }
        };
        connection.connection.onclose = (event: CloseEvent)=> {
            if (id) {
                clearInterval(id);
            }
            // 如果还是在界面上显示的那个连接
            if (this.connections.get(app) == connection) {
                this.connections.delete(app);
                if (event.code != 1000 && !connection.address) {
                    // 如果还没建立好就出错了，就弹窗提示这个错误
                    alert(`出错了 ${event.code}`);
                }
                this.ref.tick();
            }
        };
    }
}
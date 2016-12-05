import {Injectable, ApplicationRef} from "@angular/core";
import {Http} from "@angular/http";
import {App, AppStatus, Action} from "./app";
import {SettingsService} from "./settings.sevices";
import * as fs from "fs";
import * as path from "path";
import * as child_process from "child_process";
import {ChildProcess} from "child_process";
import {remote} from "electron";
import "rxjs/Rx";
import {AppLocal} from "./app-local";
import * as ini from "ini";
import Timer = NodeJS.Timer;
import {DownloadService} from "./download.service";
import {InstallOption} from "./install-option";
import {InstallService} from "./install.service";
import {ComparableSet} from "./shared/ComparableSet";

const Aria2 = require('aria2');
const sudo = require('electron-sudo');

interface Connection {
    connection: WebSocket, address: string | null
}

@Injectable()
export class AppsService {

    private apps: Map<string,App>;

    constructor(private http: Http, private settingsService: SettingsService, private ref: ApplicationRef,
                private downloadService: DownloadService, private installService: InstallService) {
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
                    value = app[key]["zh-CN"];
                }
                app[key] = value;
            });

            // 去除平台无关的内容
            ['actions', 'dependencies', 'references', 'version'].forEach((key) => {
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

    // async update(app: App) {
    //     const updateServer = "https://thief.mycard.moe/update/metalinks/";
    //
    //     if (app.isReady() && app.local!.version != app.version) {
    //         let checksumMap = await this.installService.getChecksumFile(app)
    //
    //         let latestFiles = new ComparableSet();
    //
    //     }
    //
    //     if (app.isInstalled() && app.version != (<AppLocal>app.local).version) {
    //         let checksumMap = await this.installService.getChecksumFile(app);
    //         let filesMap = (<AppLocal>app.local).files;
    //         let deleteList: string[] = [];
    //         let addList: string[] = [];
    //         let changeList: string[] = [];
    //         for (let [file,checksum] of filesMap) {
    //             let t = checksumMap.get(file);
    //             if (!t) {
    //                 deleteList.push(file);
    //             } else if (t !== checksum) {
    //                 changeList.push(file);
    //             }
    //         }
    //         for (let file of checksumMap.keys()) {
    //             if (!filesMap.has(file)) {
    //                 changeList.push(file);
    //             }
    //         }
    //         let metalink = await this.http.post(updateServer + app.id, changeList).map((response) => response.text())
    //             .toPromise();
    //         let meta = new DOMParser().parseFromString(metalink, "text/xml");
    //         let filename = meta.getElementsByTagName('file')[0].getAttribute('name');
    //         let dir = path.join(path.dirname((<AppLocal>app.local).path), "downloading");
    //         let a = await this.downloadService.addMetalink(metalink, dir);
    //
    //         for (let file of deleteList) {
    //             await this.installService.deleteFile(file);
    //         }
    //         (<AppLocal>app.local).version = app.version;
    //         (<AppLocal>app.local).files = checksumMap;
    //         localStorage.setItem(app.id, JSON.stringify(app.local));
    //         await this.installService.extract(path.join(dir, filename), (<AppLocal>app.local).path);
    //         let children = this.appsService.findChildren(app);
    //         for (let child of children) {
    //             if (child.isInstalled()) {
    //                 await this.installService.uninstall(child, false);
    //                 // this.installService.add(child, new InstallOption(child, path.dirname(((<AppLocal>app.local).path))));
    //                 await this.installService.getComplete(child);
    //                 console.log("282828")
    //             }
    //         }
    //
    //     }
    // }

    async install(app: App, option: InstallOption) {
        const addDownloadTask = async(app: App, dir: string) => {
            let metalinkUrl = app.download;
            if (app.id === "ygopro") {
                metalinkUrl = "https://thief.mycard.moe/metalinks/ygopro-" + process.platform + ".meta4";
            }
            let metalink = await this.http.get(metalinkUrl).map((response) => {
                return response.text()
            }).toPromise();
            app.status.status = "downloading";
            let downloadId = await this.downloadService.addMetalink(metalink, dir);
            let observable = this.downloadService.downloadProgress(downloadId);
            return new Promise((resolve, reject) => {
                observable.subscribe((task) => {
                    if (task.totalLength) {
                        app.status.total = task.totalLength;
                    } else {
                        app.status.total = 0;
                    }
                    app.status.progress = task.completedLength;

                    console.log(task);

                    if (task.downloadSpeed) {
                        let currentSpeed = parseInt(task.downloadSpeed);
                        const speedUnit = ["Byte/s", "KB/s", "MB/s", "GB/s", "TB/s"];
                        let currentUnit = Math.floor(Math.log(currentSpeed) / Math.log(1024));
                        console.log(currentSpeed, currentUnit);
                        app.status.progressMessage = (currentSpeed / 1024 ** currentUnit).toFixed(1) + " " + speedUnit[currentUnit];
                    } else {
                        app.status.progressMessage = '';
                    }
                    this.ref.tick();
                }, (error) => {
                    reject(error);
                }, async() => {
                    app.status.status = "waiting";
                    let files = await this.downloadService.getFile(downloadId);
                    resolve({app: app, files: files});
                })
            });
        };
        try {
            let apps: App[] = [];
            let dependencies = app.findDependencies().filter((dependency) => {
                return !dependency.isInstalled();
            });
            apps.push(...dependencies, app);
            let downloadPath = path.join(option.installLibrary, 'downloading');
            let tasks: Promise<any>[] = [];
            for (let a of apps) {
                tasks.push(addDownloadTask(a, downloadPath));
            }
            let downloadResults = await Promise.all(tasks);
            for (let result of downloadResults) {
                console.log(result);
                let o = new InstallOption(result.app, option.installLibrary);
                o.downloadFiles = result.files;
                this.installService.push({app: result.app, option: o});
            }
        } catch (e) {
            console.log(e);
            throw e;
        }
    }

    findChildren(app: App): App[] {
        let children: App[] = [];
        for (let [id,child] of this.apps) {
            if (child.parent === app) {
                children.push(child);
            }
        }
        return children;
    }

    async runApp(app: App, action_name = 'main') {
        let children = this.findChildren(app);
        let cwd = (<AppLocal>app.local).path;
        let action: Action = <Action>app.actions.get(action_name);
        let args: string[] = [];
        let env = {};
        for (let child of children) {
            if (child.isInstalled()) {
                let _action = child.actions.get(action_name);
                if (_action) {
                    action = _action
                }
            }
        }
        let execute = path.join(cwd, action.execute);
        if (app.id == 'th123') {
            let th105 = <App>app.references.get('th105');
            if (th105.isInstalled()) {
                const config_file = path.join((<AppLocal>app.local).path, 'configex123.ini');
                let config = await new Promise((resolve, reject) => {
                    fs.readFile(config_file, {encoding: 'utf-8'}, (error, data) => {
                        if (error) return reject(error);
                        resolve(ini.parse(data));
                    });
                });
                config['th105path'] = {path: (<AppLocal>th105.local).path};
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
        }

        if (action.open) {
            let np2 = <App>action.open;
            let openAction: Action;
            openAction = <Action>np2.actions.get('main');
            let openPath = (<AppLocal>np2.local).path;
            if (action.open.id == 'np2fmgen') {
                const config_file = path.join((<AppLocal>(<App>action.open).local).path, 'np21nt.ini');
                let config = await new Promise((resolve, reject) => {
                    fs.readFile(config_file, {encoding: 'utf-8'}, (error, data) => {
                        if (error) return reject(error);
                        resolve(ini.parse(data));
                    });
                });
                const default_config = {
                    clk_mult: '48',
                    DIPswtch: '3e f3 7b',
                    SampleHz: '44100',
                    Latencys: '100',
                    MIX_TYPE: 'true',
                    windtype: '0'
                };
                config['NekoProject21'] = Object.assign({}, default_config, config['NekoProject21']);
                config['NekoProject21']['HDD1FILE'] = path.win32.join(process.platform == 'win32' ? '' : 'Z:', (<AppLocal>app.local).path, action.execute);
                await new Promise((resolve, reject) => {
                    fs.writeFile(config_file, ini.stringify(config), (error) => {
                        if (error) {
                            reject(error)
                        } else {
                            resolve()
                        }
                    })
                });
                args.push(openAction.execute);
                args = args.concat(openAction.args);
                let wine = <App>openAction.open;
                openPath = (<AppLocal>wine.local).path;
                openAction = <Action>(<App>openAction.open).actions.get('main');
                cwd = (<AppLocal>np2.local).path;
            }
            args = args.concat(openAction.args);
            args.push(action.execute);
            execute = path.join(openPath, openAction.execute);
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
    maotama: Promise<ChildProcess>;

    async network(app: App, server: any) {
        if (!this.maotama) {
            this.maotama = new Promise((resolve, reject) => {
                let child = sudo.fork('maotama', [], {stdio: ['inherit', 'inherit', 'inherit', 'ipc']});
                child.once('message', () => resolve(child));
                child.once('error', reject);
                child.once('exit', reject);
            })
        }
        let child: ChildProcess;
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
        let id: Timer | null;
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
                    if (id) {
                        clearInterval(id);
                        id = null;
                    }
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
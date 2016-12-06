import {Injectable, ApplicationRef, EventEmitter} from "@angular/core";
import {Http} from "@angular/http";
import {App, AppStatus, Action} from "./app";
import {SettingsService} from "./settings.sevices";
import * as fs from "fs";
import * as path from "path";
import * as child_process from "child_process";
import {ChildProcess} from "child_process";
import {remote} from "electron";
import "rxjs/Rx";
import * as readline from "readline";
import {AppLocal} from "./app-local";
import * as ini from "ini";
import {DownloadService} from "./download.service";
import {InstallOption} from "./install-option";
import {ComparableSet} from "./shared/ComparableSet";
import {Observable, Observer} from "rxjs/Rx";
import Timer = NodeJS.Timer;
import mkdirp = require("mkdirp");
import ReadableStream = NodeJS.ReadableStream;

const Aria2 = require('aria2');
const sudo = require('electron-sudo');

interface InstallTask {
    app: App;
    option: InstallOption;
}
interface InstallStatus {
    status: string;
    progress: number;
    total: number;
    lastItem: string;
}
interface Connection {
    connection: WebSocket, address: string | null
}

@Injectable()
export class AppsService {

    private apps: Map<string,App>;

    constructor(private http: Http, private settingsService: SettingsService, private ref: ApplicationRef,
                private downloadService: DownloadService) {

        if (process.platform === "win32") {
            if (process.env['NODE_ENV'] == 'production') {
                this.tarPath = path.join(process.resourcesPath, 'bin', 'bsdtar.exe');
            } else {
                this.tarPath = path.join('bin', 'bsdtar.exe');
            }
        } else {
            this.tarPath = "bsdtar"
        }
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
        if (!app.isInstalled()) {
            let apps: App[] = [];
            let dependencies = app.findDependencies().filter((dependency) => {
                return !dependency.isInstalled();
            });
            apps.push(...dependencies, app);
            try {
                let downloadPath = path.join(option.installLibrary, 'downloading');
                let tasks: Promise<any>[] = [];
                for (let a of apps) {
                    tasks.push(addDownloadTask(a, downloadPath));
                }
                let downloadResults = await Promise.all(tasks);
                let installTasks: Promise<void>[] = [];
                for (let result of downloadResults) {
                    console.log(result);
                    let o = new InstallOption(result.app, option.installLibrary);
                    o.downloadFiles = result.files;

                    let task = this.push({app: result.app, option: o});
                    installTasks.push(task);
                }
                await Promise.all(installTasks);

            } catch (e) {
                for (let a of apps) {
                    if (!a.isReady()) {
                        a.status.status = 'init';
                    }
                }
                console.log(e);
                throw e;
            }
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
            let np2 = action.open;
            let openAction: Action;
            openAction = np2.actions.get('main')!;
            let openPath = np2.local!.path;
            if (action.open.id == 'np2fmgen') {
                const config_file = path.join(action.open!.local!.path, 'np21nt.ini');
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
                config['NekoProject21']['HDD1FILE'] = path.win32.join(process.platform == 'win32' ? '' : 'Z:', app.local!.path, action.execute);
                config['NekoProject21']['fontfile'] = path.win32.join(process.platform == 'win32' ? '' : 'Z:', app.local!.path, 'font.bmp');
                await new Promise((resolve, reject) => {
                    fs.writeFile(config_file, ini.stringify(config), (error) => {
                        if (error) {
                            reject(error)
                        } else {
                            resolve()
                        }
                    })
                });

                if (process.platform != 'win32') {
                    args.push(openAction.execute);
                    args = args.concat(openAction.args);
                    let wine = openAction.open!;
                    openPath = wine.local!.path;
                    openAction = openAction!.open!.actions.get('main')!;
                }
                cwd = np2.local!.path;
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

        let connection = this.connections.get(app);
        if (connection) {
            connection.connection.close();
        }
        console.log(server.url);
        connection = {connection: new WebSocket(server.url), address: null};
        let id: Timer | null;
        this.connections.set(app, connection);
        connection.connection.onmessage = (event) => {
            console.log(event.data);
            let [action, args] = event.data.split(' ', 2);
            let [address, port] = args.split(':');
            switch (action) {
                case 'LISTEN':
                    connection!.address = args;
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
                if (event.code != 1000 && !connection!.address) {
                    alert(`出错了 ${event.code}`);
                }
            }
            // 如果还没建立好就出错了，就弹窗提示这个错误
            this.ref.tick();
        };
    }

    tarPath: string;
    installingId: string = '';
    eventEmitter = new EventEmitter<void>();

    readonly checksumURL = "https://thief.mycard.moe/checksums/";
    readonly updateServerURL = 'https://thief.mycard.moe/update/metalinks';

    installQueue: Map<string,InstallTask> = new Map();

    map: Map<string,string> = new Map();

    private createId(): string {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }

        return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
            s4() + '-' + s4() + s4() + s4();
    }

    // installProgress(id: string): Observable<InstallStatus>|undefined {
    //     let app = this.map.get(id);
    //     if (app) {
    //
    //     }
    // }

    async push(task: InstallTask): Promise<void> {
        if (!task.app.readyForInstall()) {
            await new Promise((resolve, reject) => {
                this.eventEmitter.subscribe(() => {
                    if (task.app.readyForInstall()) {
                        resolve();
                    } else if (task.app.findDependencies().find((dependency: App) => !dependency.isInstalled())) {
                        reject("Dependencies failed");
                    }
                });
            });
        }
        await this.doInstall(task);
    }

    async doInstall(task: InstallTask) {
        try {
            let app = task.app;
            let dependencies = app.findDependencies();
            let readyForInstall = dependencies.every((dependency) => {
                return dependency.isReady();
            });
            if (readyForInstall) {
                let option = task.option;
                let installDir = option.installDir;
                // if (!app.isInstalled()) {
                let checksumFile = await this.getChecksumFile(app);
                if (app.parent) {
                    // mod需要安装到parent路径
                    installDir = app.parent.local!.path;
                    let parentFiles = new ComparableSet(Array.from(app.parent.local!.files.keys()));
                    let appFiles = new ComparableSet(Array.from(checksumFile.keys()));
                    let conflictFiles = appFiles.intersection(parentFiles);
                    if (conflictFiles.size > 0) {
                        let backupPath = path.join(option.installLibrary, "backup", app.parent.id);
                        await this.backupFiles(app.parent.local!.path, backupPath, conflictFiles);
                    }
                }
                let allFiles = new Set(checksumFile.keys());
                app.status.status = "installing";
                app.status.total = allFiles.size;
                app.status.progress = 0;
                // let timeNow = new Date().getTime();
                for (let file of option.downloadFiles) {
                    await this.createDirectory(installDir);
                    let interval = setInterval(() => {
                    }, 500);
                    await new Promise((resolve, reject) => {
                        this.extract(file, installDir).subscribe(
                            (lastItem: string) => {
                                app.status.progress += 1;
                                app.status.progressMessage = lastItem;
                            },
                            (error) => {
                                reject(error);
                            },
                            () => {
                                resolve();
                            });
                    });
                    clearInterval(interval);
                }
                await this.postInstall(app, installDir);
                console.log("post install success");
                let local = new AppLocal();
                local.path = installDir;
                local.files = checksumFile;
                local.version = app.version;
                app.local = local;
                this.saveAppLocal(app);
                app.status.status = "ready";
            }
            // }
        } catch (e) {
            console.log("exception in doInstall", e);
            throw e;
        }
        finally {
            this.eventEmitter.emit();
        }

    }

    createDirectory(dir: string) {
        return new Promise((resolve, reject) => {
            mkdirp(dir, resolve);
        })
    }

    extract(file: string, dir: string): Observable<string> {
        return Observable.create((observer: Observer<string>) => {
            let tarProcess = child_process.spawn(this.tarPath, ['xvf', file, '-C', dir]);
            let rl = readline.createInterface({
                input: <ReadableStream>tarProcess.stderr,
            });
            rl.on('line', (input: string) => {
                observer.next(input.split(" ", 2)[1]);
            });
            tarProcess.on('exit', (code) => {
                if (code === 0) {
                    observer.complete();
                } else {
                    observer.error(code);
                }
            });
            return () => {
            }
        })
    }

    async postInstall(app: App, appPath: string) {
        let action = app.actions.get('install');
        if (action) {
            let env = Object.assign({}, action.env);
            let command: string[] = [];
            command.push(path.join(appPath, action.execute));
            command.push(...action.args);
            let open = action.open;
            if (open) {
                let openAction: any = open.actions.get("main");
                env = Object.assign(env, openAction.env);
                command.unshift(...openAction.args);
                command.unshift(path.join((<AppLocal>open.local).path, openAction.execute));
            }
            return new Promise((resolve, reject) => {
                let child = child_process.spawn(<string>command.shift(), command, {
                    env: env,
                    stdio: 'inherit',
                    shell: true,
                });
                child.on('error', (error) => {
                    reject(error);
                });
                child.on('exit', (code) => {
                    if (code === 0) {
                        resolve(code);
                    } else {
                        reject(code);
                    }
                })
            })
        }
    }

    saveAppLocal(app: App) {
        if (app.local) {
            localStorage.setItem(app.id, JSON.stringify(app.local));
        }
    }

    async backupFiles(dir: string, backupDir: string, files: Iterable<string>) {
        for (let file of files) {
            await new Promise(async(resolve, reject) => {
                let srcPath = path.join(dir, file);
                let backupPath = path.join(backupDir, file);
                await this.createDirectory(path.dirname(backupPath));
                fs.unlink(backupPath, (err) => {
                    fs.rename(srcPath, backupPath, resolve);
                });
            });
        }
    }

    async restoreFiles(dir: string, backupDir: string, files: Iterable<string>) {
        for (let file of files) {
            await new Promise((resolve, reject) => {
                let backupPath = path.join(backupDir, file);
                let srcPath = path.join(dir, file);
                fs.unlink(srcPath, (err) => {
                    fs.rename(backupPath, srcPath, resolve);
                })
            })
        }
    }

    async getChecksumFile(app: App): Promise<Map<string,string> > {
        let checksumUrl = this.checksumURL + app.id;
        if (["ygopro", 'desmume'].includes(app.id)) {
            checksumUrl = this.checksumURL + app.id + "-" + process.platform;
        }
        return this.http.get(checksumUrl)
            .map((response) => {
                let map = new Map<string,string>();
                for (let line of response.text().split('\n')) {
                    if (line !== "") {
                        let [checksum,filename]=line.split('  ', 2);
                        if (filename.endsWith("\\") || filename.endsWith("/")) {
                            map.set(filename, "");
                        }
                        map.set(filename, checksum);
                    }
                }
                return map;
            }).toPromise();
    }


    deleteFile(file: string): Promise<string> {
        return new Promise((resolve, reject) => {
            fs.lstat(file, (err, stats) => {
                if (err) return resolve(path);
                if (stats.isDirectory()) {
                    fs.rmdir(file, (err) => {
                        resolve(file);
                    });
                } else {
                    fs.unlink(file, (err) => {
                        resolve(file);
                    });
                }
            });
        })
    }

    async uninstall(app: App) {
        let children = this.findChildren(app);
        let hasInstalledChild = children.find((child) => {
            return child.isInstalled();
        });
        if (hasInstalledChild) {
            throw "无法卸载，还有依赖此程序的游戏。"
        }

        if (app.isReady()) {
            app.status.status = "uninstalling";
            let appDir = app.local!.path;
            let files = Array.from(app.local!.files.keys()).sort().reverse();

            app.status.total = files.length;

            for (let file of files) {
                app.status.progress += 1;
                await this.deleteFile(path.join(appDir, file));
            }

            if (app.parent) {
                let backupDir = path.join(path.dirname(appDir), "backup", app.parent.id)
                let fileSet = new ComparableSet(files);
                let parentSet = new ComparableSet(Array.from(app.parent.local!.files.keys()));
                let difference = parentSet.intersection(fileSet);
                if (difference) {
                    this.restoreFiles(appDir, backupDir, Array.from(difference))
                }
            }
            app.local = null;
            localStorage.removeItem(app.id);
        }

    }
}
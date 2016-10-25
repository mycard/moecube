import {Injectable} from "@angular/core";
import {Http} from "@angular/http";
import "rxjs/Rx";
import {App} from "./app";
import {TranslateService} from "ng2-translate";
import {InstallConfig} from "./install-config";
import {SettingsService} from "./settings.sevices";

declare var process;
const os = window['System']._nodeRequire('os');
const fs = window['System']._nodeRequire('fs');
const path = window['System']._nodeRequire('path');
const mkdirp = window['System']._nodeRequire('mkdirp');
const electron = window['System']._nodeRequire('electron');
const Aria2 = window['System']._nodeRequire('aria2');
const execFile = window['System']._nodeRequire('child_process').execFile;

@Injectable()
export class AppsService {


    private _currentApp: App;

    get currentApp(): App {
        return this._currentApp;
    }

    set currentApp(app: App) {
        this._currentApp = app;
    }

    constructor(private http: Http, private translate: TranslateService, private settings: SettingsService) {
        let loop = setInterval(()=> {
            this.aria2.tellActive().then((res)=> {
                if (res) {
                    res.map((v)=> {
                        let index = this.downloadsInfo.findIndex((info)=> {
                            return info.gid == v.gid;
                        });
                        this.downloadsInfo[index].progress = (v.completedLength / v.totalLength) * 100;

                    });
                }
            })
        }, 1000);

        this.getApps(()=> {
            //console.log(appsService.data)
            if (this.data.size > 0) {
                this.currentApp = this.data.get('ygopro');
            }
        });
    }

    private data: Map<string,App>;

    get allApps(): Map<string,App> {
        return this.data;
    }

    //[{"id": "th01", "gid": "aria2gid", "status": "active/install/complete/wait", "progress": "0-100"}]
    downloadsInfo = [];

    //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
    // th01
    waitInstallQueue = [];


    aria2IsOpen = false;


    _aria2;
    get aria2() {
        if (!this._aria2) {
            this._aria2 = new Aria2();
            console.log("new aria2");
            this._aria2.onopen = ()=> {
                console.log('aria2 open');
            };
            this._aria2.onclose = ()=> {
                console.log('aria2 close');
                this.aria2IsOpen = false;
            };
            this._aria2.onDownloadComplete = (response)=> {
                console.log("download response: ", response);
                this._aria2.tellStatus(response.gid, (err, res)=> {
                    let index = this.downloadsInfo.findIndex((v)=> {
                        return v.gid == res.gid
                    });
                    if (index !== -1) {
                        if (res.followedBy) {
                            this.downloadsInfo[index].gid = res.followedBy[0];
                            this.downloadsInfo[index].progress = 0;

                        } else {
                            this.downloadsInfo[index].status = "wait";
                            let tarObj = {
                                id: this.downloadsInfo[index].id,
                                xzFile: res.files[0].path,
                                installDir: this.installConfig.installDir
                            };
                            let promise = new Promise((resolve, reject)=> {
                                let refs = this.searchApp(this.downloadsInfo[index].id).references;
                                console.log(refs);
                                //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
                                let waitObj;

                                let waitRef = ["runtime", "emulator", "dependency"];
                                if (!this.isEmptyObject(refs)) {
                                    refs[process.platform].map((ref)=> {
                                        if (waitRef.includes(ref.type)) {
                                            if (!this.checkInstall(ref.id)) {
                                                if (!waitObj) {
                                                    waitObj = {
                                                        id: this.downloadsInfo[index].id,
                                                        wait: [ref.id],
                                                        resolve: resolve,
                                                        tarObj: tarObj
                                                    }
                                                } else {
                                                    waitObj.wait.push(ref.id);
                                                }
                                            }
                                        }
                                    });
                                }
                                console.log("wait obj:", waitObj);

                                if (waitObj) {
                                    this.waitInstallQueue.push(waitObj);
                                } else {
                                    resolve();
                                }

                            }).then(()=> {
                                console.log(tarObj);
                                this.tarPush(tarObj);
                            });
                            promise.catch((err)=> {
                                console.log("err", err);
                            })
                        }
                    } else {
                        console.log("cannot found download info!");
                    }
                });
            };
            this._aria2.onmessage = (m)=> {
                //console.log('IN:', m);
                //console.log('download infoi:', this.downloadsInfo);

            }
        }

        if (!this.aria2IsOpen) {
            this._aria2.open().then(()=> {
                console.log('aria2 websocket open')
                this.aria2IsOpen = true;
            });
        }

        return this._aria2;

    }

    _download_dir;
    get download_dir() {
        const dir = path.join(electron.remote.app.getAppPath(), 'cache');

        if (!fs.existsSync(dir)) {
            console.log('cache not exists');
            mkdirp(dir, (err)=> {
                if (err) {
                    console.error(err)
                } else {
                    console.log('create cache dir');
                }
            });
        }

        return dir;
    }

    getApps(callback) {
        this.http.get('./apps.json')
            .map(response => {
                let apps = response.json();
                let localAppData = JSON.parse(localStorage.getItem("localAppData"));
                console.log("app:", apps);
                console.log("store:", localAppData);
                apps = apps.map((app)=> {
                    if (localAppData) {
                        localAppData.map((v)=> {
                            if (v.id === app.id) {
                                app.local = v.local;
                            }
                        });
                    }
                    return app;
                });


                return apps;
            }).map(this.loadApps)
            .subscribe((apps) => {
                console.log(apps);
                this.data = apps;
                if (typeof(callback) === 'function') {
                    callback();
                }
            });
    }

    loadApps(data: any): Map<string,App> {
        let result = new Map<string,App>();
        for (let item of data) {
            let id = item["id"];
            let app = new App(item);
            result.set(id, app);
        }
        return result;
    }

    searchApp(id): App {
        return this.data.get(id);
    }

    checkInstall(id): boolean {
        if (this.searchApp(id)) {
            if (this.searchApp(id).local.path) {
                return true;
            }
        }
        return false;
    }

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

    uninstall(id: string) {
        let current = this;
        if (this.checkInstall(id)) {
            let files: string[] = this.searchApp(id).local.files.sort().reverse();
            // 删除本目录
            files.push('.');
            let install_dir = this.searchApp(id).local.path;
            return files
                .map((file)=>
                    ()=>path.join(install_dir, file)
                )
                .reduce((promise: Promise<string>, task)=>
                        promise.then(task).then(this.deleteFile)
                    , Promise.resolve(''))
                .then((value)=> {
                    this.searchApp(id).local = null;
                    localStorage.setItem("localAppData", JSON.stringify(this.data));
                });
        }

    }

    download(id, uri) {
        if (this.downloadsInfo.findIndex((v)=> {
                return v.id == id
            }) !== -1) {
            console.log("this app is downloading")
        } else {
            this.aria2.addUri([uri], {'dir': this.download_dir}, (error, gid)=> {
                if (error) {
                    console.error(error);
                }
                this.downloadsInfo.push({"id": id, "gid": gid, "status": "active", "progress": 0});
            });
        }
    }

    getDownloadInfo(id) {
        let info;
        info = this.downloadsInfo.find((v)=> {
            return v.id == id;
        });

        return info;
    }

    installConfig;

    getInstallConfig(app: App): InstallConfig {
        let id = app.id;
        let installConfig = new InstallConfig(app);
        let platform = process.platform;
        let references: InstallConfig[] = [];
        if (app.references[platform]) {
            // app.references[platform].forEach((item)=> {
            //     references.push();
            // });
        }
        installConfig.references = references;
        return installConfig;
    }

    // createInstallConfig(id) {
    //     let app = this.data.find((app)=> {
    //         return app.id == id;
    //     });
    //     let platform = process.platform;
    //     let mods = {};
    //     if (app.references[platform]) {
    //         app.references[platform].map((mod)=> {
    //             mods[mod.id] = false;
    //         });
    //
    //     }
    //
    //     let tmp = {
    //         installDir: path.join(electron.remote.app.getPath('appData'), 'mycard'),
    //         shortcut: {
    //             desktop: false,
    //             application: false
    //         },
    //         mods: mods
    //     };
    //     //console.log(tmp);
    //     this.installConfig = tmp;
    //     return tmp;
    //
    // }

    // tar
    tarQueue = [];
    isExtracting = false;

    tarPush(tarObj) {
        this.tarQueue.push(tarObj);

        if (this.tarQueue.length > 0 && !this.isExtracting) {
            this.doTar();
        }

    }

    doTar() {
        let tarPath;
        switch (process.platform) {
            case 'win32':
                tarPath = path.join(process.execPath, '..', '../../../bin/', 'tar.exe');
                break;
            case 'darwin':
                tarPath = 'bsdtar'; // for debug
                break;
            default:
                throw 'unsupported platform';
        }
        let opt = {
            maxBuffer: 20 * 1024 * 1024
        };

        let tarObj;
        if (this.tarQueue.length > 0) {
            tarObj = this.tarQueue[0];
        } else {
            console.log("Empty Queue!");

            return;
        }

        this.isExtracting = true;
        console.log("Start tar " + tarObj.id);

        let downLoadsInfoIndex = this.downloadsInfo.findIndex((v)=> {
            return v.id == tarObj.id
        });
        if (downLoadsInfoIndex !== -1) {
            this.downloadsInfo[downLoadsInfoIndex].status = "install";
        } else {
            console.log("cannot found download info!");
        }


        let xzFile = tarObj.xzFile;
        let installDir = path.join(tarObj.installDir, tarObj.id);
        if (!fs.existsSync(installDir)) {
            console.log('app dir not exists');
            mkdirp(installDir, (err)=> {
                if (err) {
                    console.error(err)
                } else {
                    console.log('create app dir');
                }
            });
        }

        let tar = execFile(tarPath, ['xvf', xzFile, '-C', installDir], opt, (err, stdout, stderr)=> {
            if (err) {
                throw err;
            }

            let logArr = stderr.toString().trim().split("\n")
                .map((log, index, array)=> {
                    return log.split(" ", 2)[1];
                });

            let appLocal = {
                id: tarObj.id,
                local: {
                    path: installDir,
                    version: "0.1",
                    files: logArr
                }
            };

            let localAppData = JSON.parse(localStorage.getItem("localAppData"));
            if (!localAppData || !Array.isArray(localAppData)) {
                localAppData = [];
            }

            let index = localAppData.findIndex((v)=> {
                return v.id == tarObj.id;
            });
            if (index === -1) {
                localAppData.push(appLocal);
            } else {
                localAppData[index] = appLocal;
            }
            localStorage.setItem("localAppData", JSON.stringify(localAppData));

            let tmp = this.tarQueue.shift();
            this.isExtracting = false;
            this.downloadsInfo[downLoadsInfoIndex].status = "complete";
            // 为了卸载时能重新显示安装条
            this.downloadsInfo.splice(downLoadsInfoIndex, 1);
            this.data.get(tarObj.id).local = appLocal.local;

            //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
            this.waitInstallQueue = this.waitInstallQueue.map((waitObj)=> {
                waitObj.wait.splice(waitObj.wait.findIndex(()=>tarObj.id), 1);
                if (waitObj.wait.length <= 0) {
                    waitObj.resolve();
                    console.log(tarObj);
                    return;
                } else {
                    return waitObj;
                }
            });
            this.waitInstallQueue = this.waitInstallQueue.filter((waitObj)=> {
                if (waitObj) {
                    return true;
                } else {
                    return false;
                }
            });

            console.log(tmp);
            console.log("this app complete!");
            console.log(localAppData);

            this.doTar();

        });

    }

    isEmptyObject(e) {
        let t;
        for (t in e)
            return !1;
        return !0
    }

    browse(id) {
        electron.remote.shell.showItemInFolder(this.searchApp(id).local.path);
    }
}

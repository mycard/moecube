import {Injectable, transition} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';
import {App} from "./app";
import {AppLocal} from "./app-local";
import {TranslateService} from "ng2-translate";

declare var process;

@Injectable()
export class AppsService {

    constructor(private http: Http, private translate: TranslateService) {
        let loop = setInterval(()=> {
            this.aria2.tellActive().then((res)=> {
                //console.log('res:', res);
                if(res) {
                    res.map((v)=>{
                        let index = this.downloadsInfo.findIndex((info)=>{
                            return info.gid == v.gid;
                        });
                        this.downloadsInfo[index].progress = (v.completedLength / v.totalLength) * 100;

                    });

                }

                //this.downloadsInfo = res;
            })
        }, 1000);

    }

    os = window['System']._nodeRequire('os');
    fs = window['System']._nodeRequire('fs');
    path = window['System']._nodeRequire('path');
    mkdirp = window['System']._nodeRequire('mkdirp');
    electron = window['System']._nodeRequire('electron');
    Aria2 = window['System']._nodeRequire('aria2');
    execFile = window['System']._nodeRequire('child_process').execFile;
    //localStorage = window['localStorage'];


    data: App[];

    //[{"id": "th01", "gid": "aria2gid", "status": "active/install/complete/wait", "progress": "0-100"}]
    downloadsInfo = [];

    //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
    // th01
    waitInstallQueue = [];


    aria2IsOpen = false;


    _aria2;
    get aria2() {
        if (!this._aria2) {
            this._aria2 = new this.Aria2();
            console.log("new aria2");
            this._aria2.onopen = ()=> {
                console.log('aria2 open');
            };
            this._aria2.onclose = ()=> {
                console.log('aria2 close');
                this.aria2IsOpen = false;
            };
            this._aria2.onDownloadComplete = (response)=> {
                console.log(response);
                this._aria2.tellStatus(response.gid, (err, res)=>{
                    console.log(res);
                    let index = this.downloadsInfo.findIndex((v)=>{return v.gid == res.gid});
                    if(index !== -1) {
                        if(res.followedBy) {
                            this.downloadsInfo[index].gid = res.followedBy[0];
                            this.downloadsInfo[index].progress = 0;

                        } else {
                            this.downloadsInfo[index].status = "wait";
                            let tarObj = {
                                id: this.downloadsInfo[index].id,
                                    xzFile: res.files[0].path,
                                    installDir: this.installConfig.installDir
                            };
                            let promise = new Promise((resolve, reject)=>{
                                let refs = this.searchApp(this.downloadsInfo[index].id).references;
                                console.log(refs);
                                //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
                                let waitObj;

                                let waitRef = ["runtime", "emulator", "dependency"];
                                if(!this.isEmptyObject(refs)) {
                                    refs[process.platform].map((ref)=>{
                                        if(waitRef.includes(ref.type)) {
                                            if(!this.checkInstall(ref.id)) {
                                                if(!waitObj) {
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

                                if(waitObj) {
                                    this.waitInstallQueue.push(waitObj);
                                } else {
                                    resolve();
                                }

                            }).then(()=>{
                                console.log(tarObj);
                                this.tarPush(tarObj);
                            });
                            promise.catch((err)=>{
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
        const dir = this.path.join(this.electron.remote.app.getAppPath(), 'cache');

        if (!this.fs.existsSync(dir)) {
            console.log('cache not exists');
            this.mkdirp(dir, (err)=> {
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
                console.log("app:",apps);
                console.log("store:",localAppData);
                apps = apps.map((app)=>{
                    if(localAppData) {
                        localAppData.map((v)=>{
                            if(v.id == app.id) {
                                app.local = v.local;
                            }
                        });
                    }
                    return app;
                });


                return apps;
            })
            .subscribe((data) => {
                this.data = data;
                for (let app of data) {
                    //console.log(app)
                    for (let attribute of ['name', 'description']) {
                        if(!app[attribute]){continue} //这句应当是不需要的, 如果转换成了 App 类型, 应当保证一定有这些属性
                        for (let locale of Object.keys(app[attribute])) {
                            let result = {};
                            result[`app.${app['id']}.${attribute}`] = app[attribute][locale];
                            this.translate.setTranslation(locale, result, true);
                        }
                    }
                }
                //console.log(this.data);
                if (typeof(callback) === 'function') {
                    callback();
                }
            });
    }


    searchApp(id): App {
        let data = this.data;
        let tmp;
        if(data) {
            tmp = data.find((v)=>v.id === id);
            return tmp;
        }
    }
    checkInstall(id): boolean {
        if(this.searchApp(id)) {
            if(this.searchApp(id).local.path) {
                return true;
            }
        }
        return false;
    }

    download(id, uri) {
        //console.log(id);
        //console.log(uri);
        //console.log(i);
        if(this.downloadsInfo.findIndex((v)=>{return v.id == id}) !== -1) {
            console.log("this app downloading")

        } else {
            this.aria2.addUri([uri], {'dir': this.download_dir}, (error, gid)=> {
                if (error) {
                    console.error(error);
                }
                //console.log(gid);
                this.downloadsInfo.push({"id": id, "gid": gid, "status": "active", "progress": 0});
            });
        }



    }

    getDownloadInfo(id) {
        let info;
        info = this.downloadsInfo.find((v)=>{
            return v.id == id;
        });

        return info;
    }

    installConfig;
    createInstallConfig(id) {
        let app = this.data.find((app)=>{return app.id == id;});
        let platform = process.platform;
        let mods = {};
        if(app.references[platform]) {
            app.references[platform].map((mod)=>{
                mods[mod.id] = false;
            });

        }

        let tmp = {
            installDir: this.path.join(this.electron.remote.app.getPath('appData'), 'mycard'),
            shortcut: {
                desktop: false,
                application: false
            },
            mods: mods
        };
        //console.log(tmp);
        this.installConfig = tmp;
        return tmp;

    }

    // tar
    tarQueue = [];
    isExtracting = false;

    tarPush(tarObj) {
        this.tarQueue.push(tarObj);

        if(this.tarQueue.length > 0 && !this.isExtracting) {
            this.doTar();
        }


    }

    doTar() {
        let tarPath;
        switch (process.platform) {
            case 'win32':
                tarPath = this.path.join(process.execPath, '..', '../../../bin/', 'tar.exe');
                break;
            case 'darwin':
                tarPath = 'bsdtar'; // for debug
                break;
            default:
                throw 'unsupported platform';
        }
        let opt = {
        };

        let tarObj;
        if(this.tarQueue.length > 0) {
            tarObj = this.tarQueue[0];
        } else {
            console.log("Empty Queue!");

            return;
        }

        this.isExtracting = true;
        console.log("Start tar " + tarObj.id);

        let downLoadsInfoIndex = this.downloadsInfo.findIndex((v)=>{return v.id == tarObj.id});
        if(downLoadsInfoIndex !== -1) {
            this.downloadsInfo[downLoadsInfoIndex].status = "install";
        } else {
            console.log("cannot found download info!");
        }




        let xzFile = tarObj.xzFile;
        let installDir = this.path.join(tarObj.installDir, tarObj.id);
        if (!this.fs.existsSync(installDir)) {
            console.log('app dir not exists');
            this.mkdirp(installDir, (err)=> {
                if (err) {
                    console.error(err)
                } else {
                    console.log('create app dir');
                }
            });
        }

        let tar = this.execFile(tarPath, ['xvf', xzFile, '-C', installDir], opt, (err, stdout, stderr)=>{
            if(err) {
                throw err;
            }

            let re = /^x\s(.*)/;
            let logArr = stderr.toString().trim().split(this.os.EOL);
            logArr = logArr.map((v)=>{
                if(v.match(re)) {
                    return v.match(re)[1];
                } else {
                    console.log("no match");
                    return v;
                }
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
            if(!localAppData || !Array.isArray(localAppData)) {
                localAppData = [];
            }

            let index = localAppData.findIndex((v)=>{
                return v.id == tarObj.id;
            });
            if(index === -1) {
                localAppData.push(appLocal);
            } else {
                localAppData[index] = appLocal;
            }
            localStorage.setItem("localAppData", JSON.stringify(localAppData));

            let tmp = this.tarQueue.shift();
            this.isExtracting = false;
            this.downloadsInfo[downLoadsInfoIndex].status = "complete";

            this.data = this.data.map((app)=>{
                if(app.id == tarObj.id) {
                    app.local = appLocal.local;
                }
                return app;
            });
            //[{"id": "th01", "wait":["wine", "dx"], resolve: resolve, tarObj: tarObj}]
            this.waitInstallQueue = this.waitInstallQueue.map((waitObj)=>{
                waitObj.wait.splice(waitObj.wait.findIndex(()=>tarObj.id), 1);
                if(waitObj.wait.length <= 0) {
                    waitObj.resolve();
                    console.log(tarObj);
                    return;
                } else {
                    return waitObj;
                }
            });
            this.waitInstallQueue = this.waitInstallQueue.filter((waitObj)=>{
                if(waitObj){
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
}

/**
 * Created by weijian on 2016/11/2.
 */
import {Injectable, ApplicationRef} from "@angular/core";
import {App, Category} from "./app";
import {InstallOption} from "./install-option";
import * as path from "path";
import * as child_process from "child_process";
import * as mkdirp from "mkdirp";
import * as readline from "readline";
import * as fs from "fs";
import {EventEmitter} from "events";
import {AppLocal} from "./app-local";
import {Http} from "@angular/http";
import {ComparableSet} from "./shared/ComparableSet"
import ReadableStream = NodeJS.ReadableStream;
import {Observable, Observer} from "rxjs/Rx";

export interface InstallTask {
    app: App;
    option: InstallOption;
}
export interface InstallStatus {
    status: string;
    progress: number;
    total: number;
    lastItem: string;
}

@Injectable()
export class InstallService {
    tarPath: string;
    installingId: string = '';
    eventEmitter: EventEmitter = new EventEmitter();

    readonly checksumURL = "https://thief.mycard.moe/checksums/";
    readonly updateServerURL = 'https://thief.mycard.moe/update/metalinks';

    installQueue: Map<string,InstallTask> = new Map();

    map: Map<string,string> = new Map();

    constructor(private http: Http, private ref: ApplicationRef) {
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

    push(task: InstallTask): string {
        let id = this.createId();
        this.installQueue.set(id, task);
        if (this.installQueue.size > 0 && this.installingId == '') {
            this.doInstall();
        }
        return id;
    }

    async doInstall() {
        if (this.installQueue.size > 0 && this.installingId == '') {
            let [id,task] = this.installQueue.entries().next().value!;
            this.installingId = id;
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
                throw e;
            }
            finally {
                this.installQueue.delete(id);
                this.installingId = '';
                if (this.installQueue.size > 0) {
                    this.doInstall();
                }
            }
        }
    }

    createDirectory(dir: string) {
        return new Promise((resolve, reject) => {
            mkdirp(dir, resolve);
        })
    }

    getComplete(app: App): Promise<App> {
        return new Promise((resolve, reject) => {
            this.eventEmitter.once(app.id, (complete: any) => {
                resolve();
            });
        });
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
                    console.log(error);
                });
                child.on('exit', (code) => {
                    if (code === 0) {
                        resolve();
                    } else {
                        reject();
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
        if (app.isReady()) {
            let appDir = app.local!.path;
            let files = Array.from(app.local!.files.keys()).sort().reverse();

            for (let file of files) {
                this.deleteFile(path.join(appDir, file));
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
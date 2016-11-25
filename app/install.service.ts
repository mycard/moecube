/**
 * Created by weijian on 2016/11/2.
 */

import {Injectable} from "@angular/core";
import {App} from "./app";
import {InstallConfig} from "./install-config";
import * as path from "path";
import * as child_process from "child_process";
import * as mkdirp from "mkdirp";
import * as readline from "readline";
import * as fs from 'fs';
import {EventEmitter} from "events";
import {AppLocal} from "./app-local";
import {Http} from "@angular/http";
import ReadableStream = NodeJS.ReadableStream;
import {AppsService} from "./apps.service";

@Injectable()
export class InstallService {
    tarPath: string;
    installQueue: Map<App,InstallConfig> = new Map();
    eventEmitter: EventEmitter = new EventEmitter();

    installingQueue: Set<App> = new Set();

    checksumUri = "https://thief.mycard.moe/checksums/";

    constructor(private http: Http, private appsService: AppsService) {
        if (process.platform === "win32") {
            this.tarPath = path.join(process.resourcesPath, 'bin', 'bsdtar.exe');
        } else {
            this.tarPath = "bsdtar"
        }
    }


    createDirectory(dir: string) {
        return new Promise((resolve, reject)=> {
            mkdirp(dir, resolve);
        })
    }

    getComplete(app: App): Promise<App> {
        return new Promise((resolve, reject)=> {
            this.eventEmitter.once(app.id, (complete)=> {
                resolve();
            });
        });
    }

    extract(file: string, destPath: string) {
        return new Promise((resolve, reject)=> {
            let tarProcess = child_process.spawn(this.tarPath, ['xvf', file, '-C', destPath]);
            let rl = readline.createInterface({
                input: <ReadableStream>tarProcess.stderr,
            });
            rl.on('line', (input)=> {
                console.log(input);
            });
            tarProcess.on('exit', (code)=> {
                if (code === 0) {
                    resolve();
                } else {
                    reject(code);
                }
            })
        });
    }

    async postInstall(app: App, appPath: string) {
        let action = app.actions.get('install');
        if (action) {
            let env = Object.assign({}, action.env);
            let command:string[] = [];
            command.push(path.join(appPath, action.execute));
            command.push(...action.args);
            let open = action.open;
            if (open) {
                let openAction:any = open.actions.get("main");
                env = Object.assign(env, openAction.env);
                command.unshift(...openAction.args);
                command.unshift(path.join((<AppLocal>open.local).path, openAction.execute));
            }
            return new Promise((resolve, reject)=> {
                let child = child_process.spawn(<string>command.shift(), command, {
                    env: env,
                    stdio: 'inherit',
                    shell: true,
                });
                child.on('error', (error)=> {
                    console.log(error);
                });
                child.on('exit', (code)=> {
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

    async backupFiles(app: App, files: Iterable<string>) {
        let backupPath = path.join((<AppLocal>app.local).path, "backup");
        await this.createDirectory(backupPath);
        for (let file of files) {
            await new Promise((resolve, reject)=> {
                let oldPath = path.join((<AppLocal>app.local).path, file);
                let newPath = path.join(backupPath, file);
                fs.rename(oldPath, newPath, resolve);
            });
        }
    }

    async getChecksumFile(app: App): Promise<Map<string,string> > {
        let checksumUrl = this.checksumUri + app.id;
        if (["ygopro", 'desmume'].includes(app.id)) {
            checksumUrl = this.checksumUri + app.id + "-" + process.platform;
        }
        let checksumMap: Map<string,string> = await this.http.get(checksumUrl)
            .map((response)=> {
                let map = new Map<string,string>();
                for (let line of response.text().split('\n')) {
                    if (line !== "") {
                        let [checksum,filename]=line.split('  ', 2);
                        map.set(filename, checksum);
                    }
                }
                return map;
            }).toPromise();
        return checksumMap;
    }

    async doInstall() {
        for (let app of this.installQueue.keys()) {
            let depInstalled = app.findDependencies()
                .every((dependency)=>dependency.isInstalled());
            if (depInstalled && !this.installingQueue.has(app)) {
                this.installingQueue.add(app);
                let options = <InstallConfig>this.installQueue.get(app);
                let checksumMap = await this.getChecksumFile(app);
                let packagePath = path.join(options.installLibrary, 'downloading', `${app.id}.tar.xz`);
                if (["ygopro", 'desmume'].includes(app.id)) {
                    packagePath = path.join(options.installLibrary, 'downloading', `${app.id}-${process.platform}.tar.xz`);
                }
                let destPath: string;
                if (app.parent) {
                    let differenceSet = new Set<string>();
                    let parentFilesMap = (<AppLocal>app.parent.local).files;
                    for (let key of checksumMap.keys()) {
                        if (parentFilesMap.has(key)) {
                            differenceSet.add(key);
                        }
                    }
                    await this.backupFiles(app.parent, differenceSet);
                    destPath = (<AppLocal>app.parent.local).path;
                } else {
                    destPath = path.join(options.installLibrary, app.id);
                    await this.createDirectory(destPath);
                }
                await this.extract(packagePath, destPath);
                await this.postInstall(app, destPath);
                let local = new AppLocal();
                local.path = destPath;
                local.files = checksumMap;
                local.version = app.version;
                app.local = local;
                this.saveAppLocal(app);
                this.eventEmitter.emit(app.id, 'install complete');
                this.installQueue.delete(app);
                this.installingQueue.delete(app);
                if (this.installQueue.size > 0) {
                    await this.doInstall()
                }
            }
        }
    }

    add(app: App, options: InstallConfig) {
        if (!this.installQueue.has(app)) {
            this.installQueue.set(app, options);
            if (!app.isInstalled()) {
                this.doInstall()
            }
        }
    }

    deleteFile(file: string): Promise<string> {
        return new Promise((resolve, reject)=> {
            fs.lstat(file, (err, stats)=> {
                if (err) return resolve(path);
                if (stats.isDirectory()) {
                    fs.rmdir(file, (err)=> {
                        resolve(file);
                    });
                } else {
                    fs.unlink(file, (err)=> {
                        resolve(file);
                    });
                }
            });
        })
    }

    async uninstall(app: App, restore = true) {
        if (!app.parent) {
            let children = this.appsService.findChildren(app);
            for (let child of children) {
                if (child.isInstalled()) {
                    await this.uninstall(child);
                }
            }
        }
        let files = Array.from((<AppLocal>app.local).files.keys()).sort().reverse();
        for (let file of files) {
            let oldFile = file;
            if (!path.isAbsolute(file)) {
                oldFile = path.join((<AppLocal>app.local).path, file);
            }
            if (restore) {
                await this.deleteFile(oldFile);
                if (app.parent) {
                    let backFile = path.join((<AppLocal>app.local).path, "backup", file);
                    await new Promise((resolve, reject)=> {
                        fs.rename(backFile, oldFile, resolve);
                    });
                }
            }
        }

        if (app.parent) {
            await this.deleteFile(path.join((<AppLocal>app.local).path, "backup"));
        } else {
            await this.deleteFile((<AppLocal>app.local).path);
        }
        app.local = null;
        localStorage.removeItem(app.id);
    }

}
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

@Injectable()
export class InstallService {
    tarPath: string;
    installQueue: Map<App,InstallConfig> = new Map();
    eventEmitter: EventEmitter = new EventEmitter();

    installingQueue: Set<App> = new Set();

    checksumUri = "http://thief.mycard.moe/checksums/";

    constructor(private http: Http) {
        if (process.platform === "win32") {
            this.tarPath = path.join(process.resourcesPath, 'bin/tar.exe');
        } else {
            this.tarPath = "tar"
        }
    }


    createDirectory(dir: string) {
        return new Promise((resolve, reject)=> {
            mkdirp(dir, resolve);
        })
    }

    getComplete(app: App): Promise<App> {
        return null;
    }

    extract(file: string, destPath: string) {
        return new Promise((resolve, reject)=> {
            let tarProcess = child_process.spawn(this.tarPath, ['xvf', file, '-C', destPath]);
            let rl = readline.createInterface({
                input: <ReadableStream>tarProcess.stderr,
            });
            rl.on('line', (input)=> {
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
            let command = [];
            command.push(path.join(appPath, action.execute));
            command.push(...action.args);
            let open = action.open;
            if (open) {
                let openAction = open.actions.get("main");
                env = Object.assign(env, openAction.env);
                command.unshift(...openAction.args);
                command.unshift(path.join(open.local.path, openAction.execute));
            }
            return new Promise((resolve, reject)=> {
                let child = child_process.spawn(command.shift(), command, {
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
            let a = JSON.stringify(app.local)
            console.log(a);
            localStorage.setItem(app.id, a);
        }
    }

    async backupFiles(app: App, files: Iterable<string>) {
        let backupPath = path.join(app.local.path, "backup");
        await this.createDirectory(backupPath);
        for (let file of files) {
            await new Promise((resolve, reject)=> {
                let oldPath = path.join(app.local.path, file);
                let newPath = path.join(backupPath, file);
                fs.rename(oldPath, newPath, resolve);
            });
        }
    }

    async doInstall() {
        for (let app of this.installQueue.keys()) {
            let depInstalled = app.findDependencies()
                .every((dependency)=>dependency.isInstalled());
            if (depInstalled && !this.installingQueue.has(app)) {
                this.installingQueue.add(app);
                let options = this.installQueue.get(app);
                let checksumMap: Map<string,string> = await this.http.get(`${this.checksumUri}${app.id}`)
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

                let packagePath = path.join(options.installLibrary, 'downloading', `${app.id}.tar.xz`);
                let destPath: string;
                if (app.parent) {
                    let differenceSet = new Set<string>();
                    let parentFilesMap = app.parent.local.files;
                    for (let key of checksumMap.keys()) {
                        if (parentFilesMap.has(key)) {
                            differenceSet.add(key);
                        }
                    }
                    await this.backupFiles(app.parent, differenceSet);
                    destPath = app.parent.local.path;
                } else {
                    destPath = path.join(options.installLibrary, app.id);
                    await this.createDirectory(destPath);
                }
                this.installQueue.delete(app);
                await this.extract(packagePath, destPath);
                await this.postInstall(app, destPath);
                let local = new AppLocal();
                local.path = destPath;
                local.files = checksumMap;
                local.version = app.version;
                app.local = local;
                this.saveAppLocal(app);
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

}
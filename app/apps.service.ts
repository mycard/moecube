import {Injectable, ApplicationRef, EventEmitter, NgZone} from "@angular/core";
import {Http} from "@angular/http";
import * as crypto from "crypto";
import {App, AppStatus, Action, FileOptions} from "./app";
import {SettingsService} from "./settings.sevices";
import * as fs from "fs";
import {createReadStream, createWriteStream} from "fs";
import * as path from "path";
import * as child_process from "child_process";
import {ChildProcess} from "child_process";
import {remote} from "electron";
import "rxjs/Rx";
import * as readline from "readline";
import {AppLocal} from "./app-local";
import * as glob from "glob";
import * as ini from "ini";
import {DownloadService, DownloadStatus} from "./download.service";
import {InstallOption} from "./install-option";
import {ComparableSet} from "./shared/ComparableSet";
import {Observable, Observer} from "rxjs/Rx";
import Timer = NodeJS.Timer;
import ReadableStream = NodeJS.ReadableStream;
const Aria2 = require('aria2');
const sudo = require('electron-sudo');
const Logger = {
    info: (...message: any[]) => {
        console.log("AppService [INFO]: ", ...message);
    },
    error: (...message: any[]) => {
        console.error("AppService [ERROR]: ", ...message);
    }
};
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

declare const System: any;

@Injectable()
export class AppsService {

    private apps: Map<string,App>;

    readonly tarPath = process.platform === "win32" ? path.join(process.env['NODE_ENV'] == 'production' ? process.resourcesPath : '', 'bin', 'bsdtar.exe') : 'bsdtar';

    constructor(private http: Http, private settingsService: SettingsService, private ref: ApplicationRef,
                private downloadService: DownloadService, private ngZone: NgZone) {
    }

    get lastVisited(): App|undefined {
        let id = localStorage.getItem("last_visited");
        if (id) {
            return this.apps.get(id);
        }
        return undefined;
    }

    set lastVisited(app: App|undefined) {
        if (app) {
            localStorage.setItem("last_visited", app.id);
        }
    }

    async loadApps() {
        let appsURL = 'https://api.mycard.moe/apps.json';
        try {
            let data = await this.http.get(appsURL).map((response) => response.json()).toPromise();
            localStorage.setItem("apps_json", JSON.stringify(data));
            this.apps = this.loadAppsList(data);
        } catch (e) {
            let data = localStorage.getItem("apps_json");
            if (data) {
                this.apps = this.loadAppsList(data);
            } else {
                this.apps = new Map();
            }
        }
        return this.apps;
    }

    async migrate() {
        await this.bundle();
        await this.migrate_v2_ygopro();
        await this.migreate_library();
    }

    async bundle() {
        try {
            const bundle = require(path.join(remote.app.getPath('appData'), 'mycard', 'bundle.json'));
            // 示例：
            // [
            //     {
            //         "app": "th105",
            //         "createShortcut": false,
            //         "createDesktopShortcut": false,
            //         "install": true,
            //         "installDir": "D:\\MyCardLibrary\\apps\\th105",
            //         "installLibrary": "D:\\MyCardLibrary"
            //     },
            //     {
            //         "app": "th105-lang-zh-CN",
            //         "createShortcut": false,
            //         "createDesktopShortcut": false,
            //         "install": true,
            //         "installDir": "D:\\MyCardLibrary\\apps\\th105",
            //         "installLibrary": "D:\\MyCardLibrary"
            //     },
            //     {
            //         "app": "th123",
            //         "createShortcut": false,
            //         "createDesktopShortcut": true,
            //         "install": true,
            //         "installDir": "D:\\MyCardLibrary\\apps\\th123",
            //         "installLibrary": "D:\\MyCardLibrary"
            //     },
            //     {
            //         "app": "th123-lang-zh-CN",
            //         "createShortcut": false,
            //         "createDesktopShortcut": false,
            //         "install": true,
            //         "installDir": "D:\\MyCardLibrary\\apps\\th123",
            //         "installLibrary": "D:\\MyCardLibrary"
            //     },
            //     {
            //         "app": "directx",
            //         "createShortcut": false,
            //         "createDesktopShortcut": false,
            //         "install": true,
            //         "installDir": "D:\\MyCardLibrary\\apps\\directx",
            //         "installLibrary": "D:\\MyCardLibrary"
            //     },
            // ]

            // {
            //     library: "D:\\MyCardLibrary",
            //     apps: ["th105", "th105-lang-zh-CN", "th123", "th123-lang-zh-CN", "directx"]
            // }
            // 文件在 D:\MyCardLibrary\cache\th105.tar.xz, D:\MyCardLibrary\cache\th105-lang-zh-CN.tar.xz ...
            // TODO: 安装那些app，不需要下载。安装成功后删除 bundle.json
        } catch (error) {

        }
    }


    async migrate_v2_ygopro() {
        // 导入萌卡 v2 的 YGOPRO
        let app = this.apps.get('ygopro')!;
        if (app.isInstalled() || localStorage.getItem('migrate_v2_ygopro')) {
            return
        }
        try {
            const legacy_ygopro_path = System._nodeRequire(path.join(remote.app.getPath('appData'), 'mycard', 'db.json')).local.ygopro.path;
            if (legacy_ygopro_path) {
                // TODO: 导入YGOPRO
                // 示例: "C:\\Users\\a915329096\\AppData\\Roaming\\mycard\\apps\\ygopro"
                // 不带任何reference，如果同盘符已有库，安装到那个库里，否则在那个盘符建个库。
                let library: string | undefined;
                if (process.platform == 'win32') {
                    let volume = legacy_ygopro_path.split(':')[0].toUpperCase();
                    for (let _library of this.settingsService.getLibraries()) {
                        if (_library.path.split(':')[0].toUpperCase() == volume) {
                            library = _library.path
                        }
                    }
                    if (!library) {
                        try {
                            let _library = path.join(volume + ':', "MyCardLibrary");
                            await this.createDirectory(_library);
                            this.settingsService.addLibrary(_library, true);
                            library = _library
                        } catch (error) {
                        }
                    }
                }
                if (!library) {
                    library = this.settingsService.getDefaultLibrary().path;
                }
                let option = new InstallOption(app, library, false, false);
                console.log('migrate ygopro', legacy_ygopro_path, library);
                await this.importApp(app, legacy_ygopro_path, option);
                localStorage.setItem('migrate_v2_ygopro', "true")
            }
        } catch (error) {
        }
    }

    async migreate_library() {
        let libraries = this.settingsService.getLibraries();
        for (let library of libraries) {
            if (library.path == path.join(remote.app.getPath("appData"), "library")) {
                library.path = path.join(remote.app.getPath("appData"), "MyCardLibrary")
            }
        }
        localStorage.setItem(SettingsService.SETTING_LIBRARY, JSON.stringify(libraries));
    }

    loadAppsList = (data: any): Map<string,App> => {
        let apps = new Map<string,App>();
        let locale = this.settingsService.getLocale();
        let platform = process.platform;

        for (let item of data) {
            let app = new App(item);
            let local = localStorage.getItem(app.id);

            if (item.files) {
                app.files = new Map(Object.entries(item.files))
            } else {
                app.files = new Map();
            }

            if (local) {
                app.local = new AppLocal();
                app.local.update(JSON.parse(local));
            }
            app.status = new AppStatus();
            if (local) {
                app.status.status = "ready";
            } else {
                app.reset()
            }

            // 去除无关语言
            for (let key of ['name', 'description', 'news']) {
                if (app[key]) {
                    let value = app[key][locale];
                    if (!value) {
                        value = app[key]["zh-CN"];
                    }
                    app[key] = value;
                }
            }

            // 去除平台无关的内容
            for (let key of ['actions', 'dependencies', 'references', 'version']) {
                if (app[key]) {
                    if (app[key][platform]) {
                        app[key] = app[key][platform];
                    }
                    else {
                        app[key] = null;
                    }
                }
            }
            apps.set(item.id, app);

        }

        // 设置App关系

        for (let [id, app] of apps) {
            let temp = app.actions;
            let map = new Map<string,any>();
            for (let action of Object.keys(temp)) {
                let openId = temp[action]["open"];
                if (openId) {
                    temp[action]["open"] = apps.get(openId);
                }
                map.set(action, temp[action]);
            }
            app.actions = map;

            for (let key of ['dependencies', 'references', 'parent']) {
                let value = app[key];
                if (value) {
                    if (Array.isArray(value)) {
                        let map = new Map<string,App>();
                        for (let appId of value) {
                            map.set(appId, apps.get(appId));
                        }
                        app[key] = map;
                    } else {
                        app[key] = apps.get(value);
                    }
                }
            }

            // 为语言包置一个默认的名字
            // 这里简易做个 i18n 的 hack
            const lang = {
                'en-US': {
                    'en-US': 'English',
                    'zh-CN': 'Simplified Chinese',
                    'zh-TW': 'Traditional Chinese',
                    'language_pack': 'Language Pack'
                },
                'zh-CN': {
                    'en-US': '英文',
                    'zh-CN': '简体中文',
                    'zh-TW': '繁体中文',
                    'language_pack': '语言包'
                }
            };
            if (!app.name && app.parent && app.isLanguage()) {
                app.name = `${app.parent.name} ${lang[locale].language_pack} (${app.locales.map((l) => lang[locale][l]).join(', ')})`
            }
        }
        return apps;
    };

    allReady(app: App) {
        return app.isReady() &&
            app.findDependencies().every((dependency) => dependency.isReady()) &&
            this.findChildren(app).every((child) => (child.isInstalled() && child.isReady()) || !child.isInstalled());
    }

    async copyFile(src: string, dst: string): Promise<any> {
        return new Promise((resolve, reject) => {
            let readable = createReadStream(src);
            readable.on('open', () => {
                let writable = createWriteStream(dst);
                writable.on("error", reject);
                writable.on("close", resolve);
                readable.pipe(writable);
            });
            readable.on("error", reject);
        });
    }

    async importApp(app: App, appPath: string, option: InstallOption) {
        if (!app.isInstalled()) {
            app.status.status = "updating";
            let checksumFiles = await this.getChecksumFile(app);
            for (let [pattern, fileOption] of app.files) {
                await new Promise((resolve, reject) => {
                    new glob.Glob(pattern, {cwd: appPath}, (err, files) => {
                        for (let file of files) {
                            // 避免被当做文件夹
                            if (fileOption.sync) {
                                checksumFiles.set(file, "DO_NOT_CARE_HASH");
                            }
                        }
                        resolve();
                    });
                })
            }
            await this.createDirectory(option.installDir);
            let sortedFiles = Array.from(checksumFiles.entries()).sort((a: string[], b: string[]): number => {
                if (a[0] > b[0]) {
                    return 1;
                } else if (a[0] < b[0]) {
                    return -1;
                } else {
                    return 0;
                }
            });
            app.status.total = sortedFiles.length;
            // 刷新进度
            let interval = setInterval(() => {
            }, 500);
            await new Promise((resolve, reject) => {
                this.ngZone.runOutsideAngular(async() => {
                    try {
                        for (let [file, checksum] of sortedFiles) {
                            let src = path.join(appPath, file);
                            let dst = path.join(option.installDir, file);
                            if (checksum === "") {
                                await this.createDirectory(dst);
                            } else {
                                try {
                                    await this.copyFile(src, dst);
                                } catch (e) {
                                } finally {
                                    app.status.progress += 1;

                                }
                            }
                        }
                        resolve();
                    } catch (e) {
                        reject(e);
                    }
                });
            });
            clearInterval(interval);
            app.local = new AppLocal();
            app.local.path = option.installDir;
            app.status.status = "ready";
            await this.update(app, true);
            this.saveAppLocal(app);
        }
    }

    sha256sum(file: string): Promise<string> {
        return new Promise((resolve, reject) => {
            let input = fs.createReadStream(file);
            const hash = crypto.createHash("sha256");
            hash.on("error", (error: Error) => {
                reject(error)
            });
            input.on("error", (error: Error) => {
                reject(error);
            });
            hash.on('readable', () => {
                let data = <Buffer>hash.read();
                if (data) {
                    resolve(data.toString("hex"));
                }
            });
            input.pipe(hash);
        });
    }

    async verifyFiles(app: App, checksumFiles: Map<string,string>, callback: () => void): Promise<Map<string,string>> {
        let result = new Map<string,string>();
        for (let [file, checksum] of checksumFiles) {
            let filePath = path.join(app.local!.path, file);
            // 如果文件不存在，随便生成一个checksum
            await new Promise((resolve, reject) => {
                fs.access(filePath, fs.constants.F_OK, async(err: Error) => {
                    if (err) {
                        result.set(file, Math.random().toString());
                    } else if (checksum === "") {
                        result.set(file, "");
                    } else {
                        let sha256sum = await this.sha256sum(filePath);
                        result.set(file, sha256sum);
                    }
                    callback();
                    resolve();
                });
            });
        }
        return result;
    }

    async update(app: App, verify = false) {
        let readyToUpdate: boolean = false;
        // 已经安装的mod
        let mods = this.findChildren(app).filter((mod) => {
            return mod.parent === app && mod.isInstalled();
        });
        // 如果是不是mod，那么要所有已经安装mod都ready
        // 如果是mod，那么要parent ready
        if (app.parent && app.parent.isReady() && app.isReady()) {
            readyToUpdate = true;
        } else {
            readyToUpdate = app.isReady() && mods.every((mod) => mod.isReady());
        }
        if (readyToUpdate && (verify || app.local!.version !== app.version )) {
            app.status.status = "updating";
            try {
                Logger.info("Checking updating: ", app);
                let latestFiles = await this.getChecksumFile(app);
                let localFiles: Map<string,string>|undefined;
                if (verify) {
                    //刷新进度条
                    let interval = setInterval(() => {
                    }, 500);
                    app.status.total = latestFiles.size;
                    await new Promise((resolve, reject) => {
                        this.ngZone.runOutsideAngular(async() => {
                            try {
                                localFiles = await this.verifyFiles(app, latestFiles, () => {
                                    app.status.progress += 1;
                                });
                                resolve();
                            } catch (e) {
                                reject(e);
                            }
                        });
                    });
                    clearInterval(interval);
                } else {
                    localFiles = app.local!.files;
                }
                let addedFiles: Set<string> = new Set<string>();
                let changedFiles: Set<string> = new Set<string>();
                let deletedFiles: Set<string> = new Set<string>();
                // 遍历寻找新增加的文件
                for (let [file, checksum] of latestFiles) {
                    if (checksum !== "" && !localFiles!.has(file)) {
                        addedFiles.add(file);
                        // changedFiles包含addedFiles，addedFiles仅供mod更新的时候使用。
                        changedFiles.add(file);
                    } else if (checksum === "" && file != ".") {
                        await this.createDirectory(path.join(app.local!.path, file));
                    }
                }
                let ignoreFiles: Set<string> = new Set();
                for (let [pattern, fileOption] of app.files) {
                    await new Promise((resolve, reject) => {
                        new glob.Glob(pattern, {cwd: app.local!.path}, (err, files) => {
                            for (let file of files) {
                                if (fileOption.ignore) {
                                    ignoreFiles.add(file);
                                }
                            }
                            resolve();
                        });
                    });
                }

                // 遍历寻找旧版本与新版本不一样的文件和新版本比旧版少了的文件
                // ignoreFiles里的文件不作处理
                for (let [file, checksum] of localFiles!) {
                    if (latestFiles.has(file)) {
                        let latestChecksum = latestFiles.get(file);
                        if (!ignoreFiles.has(file) && latestChecksum !== checksum && latestChecksum !== "") {
                            changedFiles.add(file);
                        } else if (latestChecksum === "") {
                            await this.createDirectory(path.join(app.local!.path, file));
                        }
                    } else {
                        deletedFiles.add(file);
                    }
                }

                let backupFiles: string[] = [];
                let restoreFiles: string[] = [];
                if (app.parent) {
                    let parentFiles = app.parent.local!.files;
                    // 新增加的文件和parent冲突，且不是目录,就添加backup到
                    // 改变的文件不做备份
                    for (let addedFile of addedFiles) {
                        if (parentFiles.has(addedFile) && parentFiles.get(addedFile) !== "") {
                            backupFiles.push(addedFile);
                        }
                    }
                    //如果要删除的文件parent里也有就恢复这个文件
                    for (let deletedFile of deletedFiles) {
                        restoreFiles.push(deletedFile);
                    }

                    let backupDir = path.join(path.dirname(app.local!.path), "backup", app.parent.id);
                    await this.backupFiles(app.local!.path, backupDir, backupFiles);
                    await this.restoreFiles(app.local!.path, backupDir, restoreFiles);
                } else {
                    for (let mod of mods) {
                        // 更新时，冲突文件在backup目录里，需要更新backup目录里的文件
                        // 如果changed列表与已经安装的mod有冲突，就push到backup列表里
                        // 然后先把当前的mod文件被分到mods_backup目录再解压更新，把文件备份到backup，最后从mods_backup里恢复mods文件

                        // 校验时，认为mod的文件正确，把冲突文件从changed列表里面删除掉

                        for (let changedFile of changedFiles) {
                            if (mod.local!.files.has(changedFile)) {
                                if (!verify) {
                                    backupFiles.push(changedFile);
                                } else {
                                    changedFiles.delete(changedFile);
                                }
                            }
                        }
                        let backupToDelete: string[] = [];
                        // 如果要删除的文件,mod里面存在，就删除backup目录里的文件
                        for (let deletedFile of deletedFiles) {
                            if (mod.local!.files.has(deletedFile)) {
                                backupToDelete.push(deletedFile);
                            }
                        }
                        let backupDir = path.join(path.dirname(app.local!.path), "mods_backup", app.id);
                        await this.backupFiles(app.local!.path, backupDir, backupFiles);
                        for (let file of backupToDelete) {
                            await this.deleteFile(path.join(app.local!.path, file))
                        }
                    }
                }
                await this.doUpdate(app, changedFiles, deletedFiles);
                Logger.info("Update extract finished");
                //如果不是mod，就先把自己目录里最新的冲突文件backup到backup目录
                //再把mods_backup里面的文件恢复到游戏目录
                if (!app.parent) {
                    Logger.info("Start to restore files...");
                    let modsBackupDir = path.join(path.dirname(app.local!.path), "mods_backup", app.id);
                    let appBackupDir = path.join(path.dirname(app.local!.path), "backup", app.id);
                    await this.backupFiles(app.local!.path, appBackupDir, backupFiles);
                    await this.restoreFiles(app.local!.path, modsBackupDir, backupFiles);
                }
                app.local!.version = app.version;
                app.local!.files = latestFiles;
                this.saveAppLocal(app);
                app.status.status = "ready";
                Logger.info("Update Finished: ", app);
            } catch (e) {
                Logger.error("Update Failed: ", e);
                // 如果导入失败，根据是否安装重置status
                if (app.local!.files) {
                    app.status.status = "ready";
                } else {
                    app.reset();
                }
                throw e;
            }
        }
    }

    async doUpdate(app: App, changedFiles?: Set<string>, deletedFiles?: Set<string>) {
        const updateServer = "https://thief.mycard.moe/update/";
        if (changedFiles && changedFiles.size > 0) {
            Logger.info("Update changed files: ", changedFiles);
            let updateUrl = updateServer + app.id;
            if (app.id === "ygopro") {
                let locale = this.settingsService.getLocale();
                if (!['zh-CN', 'en-US', 'ja-JP'].includes(locale)) {
                    locale = 'en-US';
                }
                updateUrl = updateUrl + '-' + process.platform + '-' + locale;
            } else if (app.id === "desmume") {
                updateUrl = updateUrl + '-' + process.platform;
            }
            let metalink = await this.http.post(updateUrl, changedFiles).map((response) => response.text()).toPromise();
            let downloadDir = path.join(path.dirname(app.local!.path), "downloading");
            let downloadId = await this.downloadService.addMetalink(metalink, downloadDir);
            await this.downloadService.progress(downloadId, (status: DownloadStatus) => {
                app.status.progress = status.completedLength;
                app.status.total = status.totalLength;
                app.status.progressMessage = status.downloadSpeedText;
                this.ref.tick();
            });
            let downloadFiles = await this.downloadService.getFiles(downloadId);
            app.status.total = 0;
            // 刷新进度条
            let interval = setInterval(() => {
            }, 500);
            for (let downloadFile of downloadFiles) {
                await new Promise((resolve, reject) => {
                    this.extract(downloadFile, app.local!.path).subscribe((file) => {
                        app.status.progressMessage = file;
                    }, (error) => {
                        reject(error);
                    }, () => {
                        resolve();
                    });
                });
            }
            clearInterval(interval);
        }
        if (deletedFiles && deletedFiles.size > 0) {
            Logger.info("Found files deleted: ", deletedFiles);
            for (let deletedFile of deletedFiles) {
                await this.deleteFile(path.join(app.local!.path, deletedFile));
            }
        }

    }

    async install(app: App, option: InstallOption) {

        const tryToInstall = async(task: InstallTask): Promise<void> => {
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
        };
        const addDownloadTask = async(app: App, dir: string): Promise<{app: App, files: string[]} > => {
            let metalinkUrl = app.download;
            if (app.id === "ygopro") {
                let locale = this.settingsService.getLocale();
                if (!['zh-CN', 'en-US', 'ja-JP'].includes(locale)) {
                    locale = 'en-US';
                }
                metalinkUrl = "https://thief.mycard.moe/metalinks/ygopro-" + process.platform + '-' + locale + ".meta4";
            } else if (app.id === "desmume") {
                metalinkUrl = "https://thief.mycard.moe/metalinks/desmume-" + process.platform + ".meta4";
            }
            app.status.status = "downloading";
            let metalink = await this.http.get(metalinkUrl).map((response) => response.text()).toPromise();
            let downloadId = await this.downloadService.addMetalink(metalink, dir);
            try {
                await this.downloadService.progress(downloadId, (status: DownloadStatus) => {
                    app.status.progress = status.completedLength;
                    app.status.total = status.totalLength;
                    app.status.progressMessage = status.downloadSpeedText;
                    this.ref.tick();
                });
            } catch (e) {
                throw e;
            }
            let files = await this.downloadService.getFiles(downloadId);
            app.status.status = "waiting";
            return {app: app, files: files}
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
                Logger.info("Start to Download", apps);
                for (let a of apps) {
                    tasks.push(addDownloadTask(a, downloadPath));
                }
                let downloadResults = await Promise.all(tasks);
                Logger.info("Download Complete", downloadResults);
                let installTasks: Promise<void>[] = [];
                for (let result of downloadResults) {
                    let o = new InstallOption(result.app, option.installLibrary);
                    o.downloadFiles = result.files;
                    let task = tryToInstall({app: result.app, option: o});
                    installTasks.push(task);
                }
                await Promise.all(installTasks);

            } catch (e) {
                for (let a of apps) {
                    if (!a.isReady()) {
                        a.reset()
                    }
                }
                throw e;
            }
        }
    }

    findChildren(app: App): App[] {
        let children: App[] = [];
        for (let [id, child] of this.apps) {
            if (child.parent === app || child.dependencies && child.dependencies.has(app.id)) {
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
        if (app.local) {
            remote.shell.showItemInFolder(app.local.path + "/.");
        }
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

    // tarPath: string;
    // installingId: string = '';
    eventEmitter = new EventEmitter<void>();

    readonly checksumURL = "https://thief.mycard.moe/checksums/";
    readonly updateServerURL = 'https://thief.mycard.moe/update/metalinks';

    // installQueue: Map<string,InstallTask> = new Map();

    map: Map<string,string> = new Map();


    // 调用前提：应用的依赖均已 Ready，应用处于下载完待安装的状态(waiting)。
    // TODO: 要把Task系统去掉吗
    async doInstall(task: InstallTask) {
        let app = task.app;

        if (!app.isWaiting()) {
            console.error('doUninstall', "应用不处于等待安装状态", app);
            throw("应用不处于等待安装状态");
        }

        if (!app.readyForInstall()) {
            console.error('doInstall', "应用依赖不齐备", app);
            throw("应用依赖不齐备");
        }

        try {
            let option = task.option;
            let installDir = option.installDir;
            let checksumFile = await this.getChecksumFile(app);
            let allFiles = new Set(checksumFile.keys());
            app.status.status = "installing";
            app.status.total = allFiles.size;
            app.status.progress = 0;
            let interval = setInterval(() => {
            }, 500);
            if (app.parent) {
                // mod需要安装到parent路径
                installDir = app.parent.local!.path;
                let parentFiles = new ComparableSet(Array.from(app.parent.local!.files.keys()));
                let appFiles = new ComparableSet(Array.from(checksumFile.keys()));
                let conflictFiles = appFiles.intersection(parentFiles);
                app.status.total += conflictFiles.size;
                if (conflictFiles.size > 0) {
                    let backupPath = path.join(option.installLibrary, "backup", app.parent.id);
                    // 文件夹不需要备份，删除
                    for (let conflictFile of conflictFiles) {
                        if (checksumFile.get(conflictFile) === '') {
                            conflictFiles.delete(conflictFile);
                        }
                    }
                    await new Promise((resolve, reject) => {
                        this.ngZone.runOutsideAngular(async() => {
                            try {
                                await this.backupFiles(app.parent!.local!.path, backupPath, conflictFiles, (n) => {
                                    app.status.progress += 1;
                                });
                                resolve();
                            } catch (e) {
                                reject(e);
                            }
                        });
                    });
                }
            }
            // let timeNow = new Date().getTime();
            for (let file of option.downloadFiles) {
                await this.createDirectory(installDir);
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
            }
            clearInterval(interval);
            await this.postInstall(app, installDir);
            console.log("post install success");
            let local = new AppLocal();
            local.path = installDir;
            local.files = checksumFile;
            local.version = app.version;
            app.local = local;
            this.saveAppLocal(app);
            app.status.status = "ready";
        } catch (e) {
            console.log("exception in doInstall", e);
            throw e;
        }
        finally {
            this.eventEmitter.emit();
        }

    }

    // 移除mkdirp函数，在这里自己实现
    // 那个路径不存在且建立目录失败、或那个路径已经存在且不是目录，reject
    // 那个路径已经存在且是目录，返回false，那个路径不存在且成功建立目录，返回true
    // TODO: 没测试
    async createDirectory(dir: string): Promise<boolean> {
        let stats: fs.Stats;
        try {
            stats = await new Promise<fs.Stats>((resolve, reject) => {
                fs.stat(dir, (error, stats) => {
                    if (error) {
                        reject(error)
                    } else {
                        resolve(stats)
                    }
                })
            });
        } catch (error) { // 路径不存在，先尝试递归上级目录，再创建自己
            await this.createDirectory(path.dirname(dir));
            return new Promise<boolean>((resolve, reject) => {
                fs.mkdir(dir, (error) => {
                    if (error) {
                        reject(error)
                    } else {
                        resolve(true);
                    }
                })
            })
        }
        if (stats.isDirectory()) { // 路径存在并且已经是目录，成功返回
            return false;
        } else { // 路径存在并且不是目录，失败。
            throw `#{dir} exists and is not a directory`
        }
    }

    extract(file: string, dir: string): Observable<string> {
        return Observable.create((observer: Observer<string>) => {
            Logger.info("Start to extract... Command Line: " + this.tarPath, file, dir);
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

    // TODO: 与runApp合并，通用处理所有Action。
    // shell: true的问题是DX特化，可以用写进app.json的方式
    async postInstall(app: App, appPath: string) {
        let action = app.actions.get('install');
        if (action) {
            let env = Object.assign({}, action.env);
            let command: string[] = [];
            command.push(action.execute);
            command.push(...action.args);
            let open = action.open;
            if (open) {
                let openAction: any = open.actions.get("main");
                env = Object.assign(env, openAction.env);
                command.unshift(...openAction.args);
                command.unshift(openAction.execute);
            }
            return new Promise((resolve, reject) => {
                let child = child_process.spawn(command.shift()!, command, {
                    cwd: appPath,
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

    async backupFiles(dir: string, backupDir: string, files: Iterable<string>, callback?: (progress: number) => void) {
        let n = 0;
        for (let file of files) {
            await new Promise(async(resolve, reject) => {
                let srcPath = path.join(dir, file);
                let backupPath = path.join(backupDir, file);
                await this.createDirectory(path.dirname(backupPath));
                fs.unlink(backupPath, (err) => {
                    fs.rename(srcPath, backupPath, resolve);
                });
                if (callback) {
                    callback(n)
                }
                n += 1;
            });
        }
    }

    async restoreFiles(dir: string, backupDir: string, files: Iterable<string>, callback?: (progress: number) => {}) {
        let n = 0;
        for (let file of files) {
            await new Promise((resolve, reject) => {
                let backupPath = path.join(backupDir, file);
                let srcPath = path.join(dir, file);
                fs.unlink(srcPath, (err) => {
                    fs.rename(backupPath, srcPath, resolve);
                });
                n += 1;
                if (callback) {
                    callback(n);
                }
            });
        }
    }

    async getChecksumFile(app: App): Promise<Map<string,string> > {
        let checksumUrl = this.checksumURL + app.id;

        if (app.id === "ygopro") {
            let locale = this.settingsService.getLocale();
            if (!['zh-CN', 'en-US', 'ja-JP'].includes(locale)) {
                locale = 'en-US';
            }
            checksumUrl = this.checksumURL + app.id + "-" + process.platform + '-' + locale;
        } else if (app.id === "desmume") {
            checksumUrl = this.checksumURL + app.id + "-" + process.platform;
        }

        return this.http.get(checksumUrl)
            .map((response) => {
                let map = new Map<string,string>();
                for (let line of response.text().split('\n')) {
                    if (line !== "") {
                        let [checksum, filename]=line.split('  ', 2);
                        // checksum文件里没有文件夹，这里添加上
                        map.set(path.dirname(filename), "");
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
            return child.isInstalled() && child.parent != app;
        });
        if (hasInstalledChild) {
            throw "无法卸载，还有依赖此程序的游戏。"
        } else if (app.isReady()) {
            for (let child of children) {
                if (child.parent === app && child.isReady()) {
                    await this.doUninstall(child);
                }
            }
            return await this.doUninstall(app);
        }
    }

    // 调用前提：应用是 Ready, 不存在依赖这个应用的其他应用
    async doUninstall(app: App) {
        if (!app.isReady()) {
            console.error('doUninstall', "应用不是 Ready 状态", app);
            throw "应用不是 Ready 状态"
        }
        if (this.findChildren(app).find((child) => child.isInstalled())) {
            console.error('doUninstall', "无法卸载，还有依赖此程序的游戏。", app);
            throw "无法卸载，还有依赖此程序的游戏。"
        }
        app.status.status = "uninstalling";
        let appDir = app.local!.path;
        let files = Array.from(app.local!.files.keys()).sort().reverse();

        app.status.total = files.length;
        // 500毫秒手动刷新，避免文件过多产生的性能问题
        let interval = setInterval(() => {
        }, 500);
        await new Promise((resolve, reject) => {
            this.ngZone.runOutsideAngular(async() => {
                try {
                    for (let file of files) {
                        app.status.progress += 1;
                        await this.deleteFile(path.join(appDir, file));
                    }
                    if (app.parent) {
                        // TODO: 建立Library模型，把拼路径的事情交给Library
                        let backupDir = path.join(path.dirname(appDir), "backup", app.parent.id);
                        let fileSet = new ComparableSet(files);
                        let parentSet = new ComparableSet(Array.from(app.parent.local!.files.keys()));
                        let difference = parentSet.intersection(fileSet);
                        if (difference) {
                            await this.restoreFiles(appDir, backupDir, Array.from(difference))
                        }
                    }
                    resolve();
                }
                catch (e) {
                    reject(e);
                }

            });
        });
        clearInterval(interval);
        app.reset()
    }
}
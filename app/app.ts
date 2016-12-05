import {AppLocal} from "./app-local";

export enum Category {
    game,
    music,
    book,
    runtime,
    emulator,
    language,
    expansion,
    module
}

// export enum DownloadStatus{
//     downloading,
//     init,
//     installing,
//     ready,
//     updating,
//     uninstalling,
//     waiting,
// }
export interface Action {
    execute: string;
    args: string[];
    env: {};
    open?: App
}

export class AppStatus {
    progress: number;
    total: number;
    private _status: string;
    get status(): string {
        return this._status
    }

    set status(status: string) {
        this.progress = 0;
        this.total = 0;
        this.progressMessage = '';
        this._status = status;
    }

    progressMessage: string;
}
export class App {
    id: string;
    name: string;          // i18n

    description: string;   //i18n
    author: string;             // English Only
    homepage: string;
    category: Category;
    parent: App;

    get download(): string {
        let downloadUrl = "https://thief.mycard.moe/metalinks/";
        return downloadUrl + this.id + ".meta4";
    }

    get checksum(): string {
        let checksumUrl = "https://thief.mycard.moe/checksum/";
        return checksumUrl + this.id;
    }

    get update(): string {
        let updateUrl = "https://thief.mycard.moe/update/";
        return updateUrl + this.id;
    }

    actions: Map<string,Action>;
    references: Map<string,App>;
    dependencies: Map<string,App>;
    locales: string[];
    news: {title: string, url: string, image: string}[];
    network: any;
    tags: string[];
    version: string;
    local: AppLocal | null;
    status: AppStatus;
    conference: string | undefined;

    isInstalled(): boolean {
        return this.status.status != 'init';
    }

    isReady(): boolean {
        return this.status.status == 'ready';
    }

    isInstalling(): boolean {
        return this.status.status == 'installing';
    }

    isWaiting(): boolean {
        return this.status.status == 'waiting';
    }

    isDownloading(): boolean {
        return this.status.status === "downloading";
    }
    isUninstalling():boolean{
       return this.status.status==="uninstalling";
    }

    runable(): boolean {
        return [Category.game].includes(this.category);
    }

    progressMessage(): string | undefined {
        return this.status.progressMessage;
    }

    constructor(app: any) {
        this.id = app.id;
        this.name = app.name;
        this.description = app.description;
        this.author = app.author;
        this.homepage = app.homepage;
        this.category = Category[app.category as string];
        this.actions = app.actions;
        this.dependencies = app.dependencies;
        this.parent = app.parent;
        this.references = app.references;
        this.locales = app.locales;
        this.news = app.news;
        this.network = app.network;
        this.tags = app.tags;
        this.version = app.version;
        this.conference = app.conference;
    }

    findDependencies(): App[] {
        if (this.dependencies && this.dependencies.size > 0) {
            let set = new Set();
            for (let dependency of this.dependencies.values()) {
                dependency.findDependencies()
                    .forEach((value) => {
                        set.add(value);
                    });
                set.add(dependency);
            }
            return Array.from(set);
        }
        return [];
    }

}
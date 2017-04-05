import {AppLocal} from './app-local';

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
    open?: App;
}
export class FileOptions {
    sync: boolean;
    ignore: boolean;
}

export class AppStatus {
    progress: number;
    total: number;
    private _status: string;
    get status(): string {
        return this._status;
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

    description: string;   // i18n
    author: string;             // English Only
    homepage: string;
    developers: {name: string, url: string}[];
    released_at: Date;
    category: Category;
    parent?: App;

    actions: Map<string, Action>;
    references: Map<string, App>;
    dependencies: Map<string, App>;
    locales: string[];
    news: {title: string, url: string, image: string, updated_at: Date}[];
    network: any;
    tags: string[];
    version: string;
    local: AppLocal | null;
    status: AppStatus;
    conference: string | undefined;
    files: Map<string, FileOptions>;
    data: any;

    icon: string;
    cover: string;
    background: string;

    price: {[currency: string]: string};
    key?: string;

    static downloadUrl(app: App, platform: string, locale: string): string {
        if (app.id === 'ygopro') {
            return `https://api.moecube.com/metalinks/${app.id}-${process.platform}-${locale}/${app.version}`;
        } else if (app.id === 'desmume') {
            return `https://api.moecube.com/metalinks/${app.id}-${process.platform}/${app.version}`;
        }
        return `https://api.moecube.com/metalinks/${app.id}/${app.version}`;
    }


    static checksumUrl(app: App, platform: string, locale: string): string {
        if (app.id === 'ygopro') {
            return `https://api.moecube.com/checksums/${app.id}-${platform}-${locale}/${app.version}`;
        } else if (app.id === 'desmume') {
            return `https://api.moecube.com/checksums/${app.id}-${platform}/${app.version}`;
        }
        return `https://api.moecube.com/checksums/${app.id}/${app.version}`;
    }

    static updateUrl(app: App, platform: string, locale: string): string {
        if (app.id === 'ygopro') {
            return `https://api.moecube.com/update/${app.id}-${platform}-${locale}/${app.version}`;
        } else if (app.id === 'desmume') {
            return `https://api.moecube.com/update/${app.id}-${platform}/${app.version}`;
        }
        return `https://api.moecube.com/update/${app.id}/${app.version}`;
    }

    isBought(): Boolean {
        // 免费或有 Key
        return !this.price || !!this.key;
    }

    isLanguage() {
        return this.category === Category.module && this.tags.includes('language');
    }

    reset() {
        this.status.status = 'init';
        this.local = null;
        localStorage.removeItem(this.id);
    }

    isInstalled(): boolean {
        return this.status.status !== 'init';
    }

    isReady(): boolean {
        return this.status.status === 'ready';
    }

    isInstalling(): boolean {
        return this.status.status === 'installing';
    }

    isWaiting(): boolean {
        return this.status.status === 'waiting';
    }

    isDownloading(): boolean {
        return this.status.status === 'downloading';
    }

    isUninstalling(): boolean {
        return this.status.status === 'uninstalling';
    }

    isUpdating(): boolean {
        return this.status.status === 'updating';
    }

    runnable(): boolean {
        return [Category.game].includes(this.category);
    }

    progressMessage(): string | undefined {
        return this.status.progressMessage;
    }

    constructor(app: any) {
        this.id = app.id;
        this.name = app.name;
        this.description = app.description;
        this.developers = app.developers;
        this.released_at = app.released_at;
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
        this.files = app.files;
        this.data = app.data;

        this.icon = app.icon;
        this.cover = app.cover;
        this.background = app.background;

        this.price = app.price;
        this.key = app.key;
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

    readyForInstall(): boolean {
        let dependencies = this.findDependencies();
        return dependencies.every((dependency) => dependency.isReady());
    }

}

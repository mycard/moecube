import {AppLocal} from "./app-local";

export enum Category {
    game, // 游戏
    music, // 音乐
    book, // 图书
    runtime, // 运行库
    emulator, // 模拟器
    language, // 语言包
    expansion, // 资料片
    module, // 创意工坊
}

// export enum Status{
//     downloading,
//     init,
//     installing,
//     ready,
//     updating,
//     uninstalling,
//     waiting,
// }

export class AppStatus {
    progress: number;
    total: number;
    status: string;
}
export class App {
    id: string;
    _name: string;          // i18n
    get name() {
        return this._name;
    }

    set name(a) {
        this._name = a;
    }

    description: string;   //i18n
    author: string;             // English Only
    homepage: string;
    category: Category;
    parent: App;
    actions: Map<string,{execute: string, args: string[], env: {}, open: App}>;
    references: Map<string,App>;
    dependencies: Map<string,App>;
    locales: string[];
    download:  string;           // meta4 url
    news: {title: string, url: string, image: string}[];
    network: any;
    tags: string[];
    version: string;
    local: AppLocal;
    status: AppStatus;

    isInstalled(): boolean {
        return this.local !== undefined;
    }

    constructor(app) {
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
        this.download = app.download;
        this.news = app.news;
        this.network = app.network;
        this.tags = app.tags;
        this.version = app.version;
    }

    findDependencies(): App[] {
        if (this.dependencies && this.dependencies.size > 0) {
            let set = new Set();
            for (let dependency of this.dependencies.values()) {
                dependency.findDependencies()
                    .forEach((value)=> {
                        set.add(value);
                    });
                set.add(dependency);
            }
            return Array.from(set);
        }
        return [];
    }
}

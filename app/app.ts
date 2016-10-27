import {AppLocal} from "./app-local";

/*
 export enum Reference_Type {
 runtime, // directx
 emulator, // wine, np2
 dependency, //
 optional, // fxtz
 language,
 host
 }
 */
/*
 export enum App_Category {
 game,
 music,
 book,
 runtime, // directx
 emulator, // wine, np2
 language
 }
 */

export class App {
    id: string;
    name: string;          // i18n
    description: string;   //i18n
    author: string;             // English Only
    homepage: string;
    category: string;
    parent: App;
    actions: {[action: string]: {execute: string, args: string[], env: {}, open: App}};
    references: Map<string,App>;
    dependencies: Map<string,App>;
    locales: string[];
    download: {[platform: string]: string};           // meta4 url
    news: {title: string, url: string, image: string}[];
    network: any;
    tags: string[];
    version: {[platform: string]: string};
    local: AppLocal;

    constructor(app) {
        this.id = app.id;
        this.name = app.name;
        this.description = app.description;
        this.author = app.author;
        this.homepage = app.homepage;
        this.category = app.category;
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
        this.local = app.local;
    }

}


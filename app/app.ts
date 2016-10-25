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
    name: {[locale: string]: string};          // i18n
    description: {[locale: string]: string};   //i18n
    author: string;             // English Only
    homepage: string;
    category: string;
    parent: App;
    actions: {[platform: string]: {[action: string]: {execute: string, args: string[], env: {}, open: string}}};
    references: Map<string,App>;
    dependencies: Map<string,App>;
    locales: string[];
    download: {[platform: string]: string};           // meta4 url
    news: {title: string, url: string, image: string}[];
    tags: string[];
    version: {[platform: string]: string};
    local: AppLocal;

    constructor(app: AppInterface) {
        this.id = app.id;
        this.name = app.name;
        this.description = app.description;
        this.author = app.author;
        this.homepage = app.homepage;
        this.category = app.category;
        this.actions = app.actions;
        this.references = app.references;
        this.locales = app.locales;
        this.download = app.download;
        this.news = app.news;
        this.tags = app.tags;
        this.version = app.version;
        this.local = app.local;
    }
}

export interface AppInterface extends App {
}
/*export interface TestInterface {
 id: string;
 name: {[locale: string]: string};
 }

 let test: TestInterface = <TestInterface>{id: '1', name: {"x": "Guy"}};

 console.log(test)*/
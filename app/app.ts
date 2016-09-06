import {AppLocal} from "./app-local";
enum Reference_Type {
    runtime, // directx
    emulator, // wine, np2
    dependency, //
    optional, // fxtz
    language
}

enum App_Category {
    game,
    music,
    book,
}

export class App {
    id: string;
    name: {[locale: string]: string};          // i18n
    description: {[locale: string]: string};   //i18n
    author: string;             // English Only
    homepage: string;
    category: string;
    actions: {[platform: string]: {[action: string]: {execute: string, args: string[], env: {}, open: string}}};
    references: {id: string, type: Reference_Type}[];
    locales: string[];
    download: string;           // meta4 url
    news: {title: string, url: string, image: string}[];
    tags: string[];
    version: string;
    local: AppLocal;
}

/*export interface TestInterface {
 id: string;
 name: {[locale: string]: string};
 }

 let test: TestInterface = <TestInterface>{id: '1', name: {"x": "Guy"}};

 console.log(test)*/
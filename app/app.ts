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
    name: Set<string>;          // i18n
    description: Set<string>;   //i18n
    author: string;             // English Only
    homepage: string;
    category: string;
    actions: Set<Set<{execute: string, args: string[], env: {}, open: string}>>;
    references: {id: string, type: Reference_Type}[];
    locales: string[];
    download: string;           // meta4 url
    news: {title: string, url: string, image: string}[];
    tags: string[]
}

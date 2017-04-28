import * as path from 'path';

export interface Achievement {
  name: string,
  description: string,
  image: string,
  unlocked: boolean,
  unlocked_at: Date,
  progress_value: number,
  progress_max: number
}

export class Cube {
  id: string;
  name: string;          // i18n

  description: string;   // i18n
  author: string;             // English Only
  homepage: string;
  developers: { name: string, url: string }[];
  released_at: Date;
  category: Category;
  parent?: Cube;

  actions: Map<string, Action>;
  references: Map<string, Cube>;
  dependencies: Map<string, Cube>;
  locales: string[];
  news: { title: string, url: string, image: string, updated_at: Date }[];
  network: any;
  tags: string[];
  version: string;
  local: CubeLocal | null;
  status: AppStatus;
  conference: string | undefined;
  files: Map<string, FileOptions>;
  data: any;

  icon: string;
  cover: string;
  background: string;

  price: { [currency: string]: string };
  key?: string;

  // 宣传片
  trailer: { url: string, type: 'video' | 'image', poster?: string }[];
  achievements: Achievement[];

  static downloadUrl(app: Cube, platform: string, locale: string): string {
    if (app.id === 'ygopro') {
      return `https://api.moecube.com/metalinks/${app.id}-${process.platform}-${locale}/${app.version}`;
    } else if (app.id === 'desmume') {
      return `https://api.moecube.com/metalinks/${app.id}-${process.platform}/${app.version}`;
    }
    return `https://api.moecube.com/metalinks/${app.id}/${app.version}`;
  }


  static checksumUrl(app: Cube, platform: string, locale: string): string {
    if (app.id === 'ygopro') {
      return `https://api.moecube.com/checksums/${app.id}-${platform}-${locale}/${app.version}`;
    } else if (app.id === 'desmume') {
      return `https://api.moecube.com/checksums/${app.id}-${platform}/${app.version}`;
    }
    return `https://api.moecube.com/checksums/${app.id}/${app.version}`;
  }

  static updateUrl(app: Cube, platform: string, locale: string): string {
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

  isWorking(): boolean {
    return this.isInstalled() && !this.isReady();
  }

  useArena(): boolean {
    return this.isReady() && this.id === 'ygopro';
  }

  useNews(): boolean {
    return this.news && this.news.length > 0;
  }

  useDescription(): boolean {
    return !!this.description;
  }

  // mods 不能在这里检查，在 Component 内还要再查一下是否真的有依赖
  useExpansions(): boolean {
    return this.isReady() && [Category.game, Category.book, Category.music].includes(this.category);
  }

  useRun(): boolean {
    return [Category.game].includes(this.category);
  }

  useYGOPro(): boolean {
    return this.isReady() && this.id === 'ygopro';
  }

  useMaotama(): boolean {
    return this.network && this.network.protocol === 'maotama';
  }

  useCustom(): boolean {
    return this.useRun() && !!this.actions.get('custom');
  }

  useAchievements(): boolean {
    return this.achievements.length > 0;
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

    this.trailer = app.trailer || [];
    this.achievements = app.achievements || [
        {
          name: '全成就',
          description: '当你完成所有成就',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/ima' +
          'ges/apps/374040/2ab3f80739854e88279b127a41a3372abf0df887.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 13,
          progress_max: 22
        },
        {
          name: '环游世界',
          description: '使用150个国家的ip登陆游戏,购买 vpn => www.150vpn.com',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/images/' +
          'apps/374040/24e386234dc5ee0351f57d719af611333f2126ed.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 0,
          progress_max: 150
        },
        {
          name: '真羡慕有两个号的人',
          description: '进行一次联机对战',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/pu' +
          'blic/images/apps/374040/3dccf7ab22b881dfa46c3aec4d042302edfed68e.jpg',
          unlocked: true,
          unlocked_at: new Date(),
          progress_value: 0,
          progress_max: 0
        }, {
          name: '全成就',
          description: '当你完成所有成就',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/ima' +
          'ges/apps/374040/2ab3f80739854e88279b127a41a3372abf0df887.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 13,
          progress_max: 22
        },
        {
          name: '环游世界',
          description: '使用150个国家的ip登陆游戏,购买 vpn => www.150vpn.com',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/images/' +
          'apps/374040/24e386234dc5ee0351f57d719af611333f2126ed.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 0,
          progress_max: 150
        },
        {
          name: '真羡慕有两个号的人',
          description: '进行一次联机对战',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/pu' +
          'blic/images/apps/374040/3dccf7ab22b881dfa46c3aec4d042302edfed68e.jpg',
          unlocked: true,
          unlocked_at: new Date(),
          progress_value: 0,
          progress_max: 0
        }, {
          name: '全成就',
          description: '当你完成所有成就',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/ima' +
          'ges/apps/374040/2ab3f80739854e88279b127a41a3372abf0df887.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 13,
          progress_max: 22
        },
        {
          name: '环游世界',
          description: '使用150个国家的ip登陆游戏,购买 vpn => www.150vpn.com',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/public/images/' +
          'apps/374040/24e386234dc5ee0351f57d719af611333f2126ed.jpg',
          unlocked: false,
          unlocked_at: null,
          progress_value: 0,
          progress_max: 150
        },
        {
          name: '真羡慕有两个号的人',
          description: '进行一次联机对战',
          image: 'http://cdn.edgecast.steamstatic.com/steamcommunity/pu' +
          'blic/images/apps/374040/3dccf7ab22b881dfa46c3aec4d042302edfed68e.jpg',
          unlocked: true,
          unlocked_at: new Date(),
          progress_value: 0,
          progress_max: 0
        }
        // ,
        // {
        //   name: string, description: string, image: string,
        //   unlocked: boolean, unlocked_at: Date, progress_value: 0, progress_max: 0
        // },
        // {
        //   name: string, description: string, image: string,
        //   unlocked: boolean, unlocked_at: Date, progress_value: 0, progress_max: 0
        // },
        // {
        //   name: string, description: string, image: string,
        //   unlocked: boolean, unlocked_at: Date, progress_value: 0, progress_max: 0
        // }
      ];
  }

  findDependencies(): Cube[] {
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

export interface Action {
  execute: string;
  args: string[];
  env: {};
  open?: Cube;
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

/**
 * Created by zh99998 on 16/9/6.
 */
export class CubeLocal {
  path: string;
  version: string;
  files: Map<string, string>;
  action: Map<string, { execute: string, args: string[], env: {}, open: Cube }>;

  update(local: any) {
    this.path = local.path;
    this.version = local.version;
    let files = new Map<string, string>();
    for (let filename of Object.keys(local.files)) {
      files.set(filename, local.files[filename]);
    }
    this.files = files;
  }

  toJSON() {
    let t: any = {};
    for (let [k, v] of Object.entries(this.files)) {
      t[k] = v;
    }
    return { path: this.path, version: this.version, files: t };
  }

}

/**
 * Created by weijian on 2016/10/24.
 */

export class InstallOption {
  app: Cube;
  downloadFiles: string[];
  installLibrary: string;

  get installDir(): string {
    return path.join(this.installLibrary, this.app.id);
  }

  createShortcut: boolean;
  createDesktopShortcut: boolean;

  constructor(app: Cube, installLibrary = '', shortcut = false, desktopShortcut = false) {
    this.app = app;
    this.createShortcut = shortcut;
    this.createDesktopShortcut = desktopShortcut;
    this.installLibrary = installLibrary;
  }
}

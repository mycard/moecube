import {App} from "./app";
/**
 * Created by weijian on 2016/10/24.
 */

export class InstallConfig {
    app: App;
    install: boolean;
    installLibrary: string;
    installDir: string;
    createShortcut: boolean;
    createDesktopShortcut: boolean;
    references: InstallConfig[];

    constructor(app: App, installLibrary = "", installDir = "", install = true, shortcut = false, desktopShortcut = false) {
        this.app = app;
        this.createShortcut = shortcut;
        this.createDesktopShortcut = desktopShortcut;
        this.install = install;
        this.installDir = installDir;
        this.installLibrary = installLibrary;
    }
}
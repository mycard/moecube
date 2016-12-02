import {App} from "./app";
import * as path from "path"
/**
 * Created by weijian on 2016/10/24.
 */

export class InstallOption {
    app: App;
    downloadFiles: string[];
    installLibrary: string;

    get installDir(): string {
        return path.join(this.installLibrary, this.app.id);
    }

    createShortcut: boolean;
    createDesktopShortcut: boolean;

    constructor(app: App, installLibrary = "", shortcut = false, desktopShortcut = false) {
        this.app = app;
        this.createShortcut = shortcut;
        this.createDesktopShortcut = desktopShortcut;
        this.installLibrary = installLibrary;
    }
}
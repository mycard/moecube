import {App} from './app';
/**
 * Created by zh99998 on 16/9/6.
 */
export class AppLocal {
    path: string;
    version: string;
    files: Map<string, string>;
    action: Map<string, {execute: string, args: string[], env: {}, open: App}>;

    update(local: any) {
        this.path = local.path;
        this.version = local.version;
        const files = new Map<string, string>();
        for (const filename of Object.keys(local.files)) {
            files.set(filename, local.files[filename]);
        }
        this.files = files;
    }

    toJSON() {
        const t: any = {};
        for (const [k, v] of this.files) {
            t[k] = v;
        }
        return {path: this.path, version: this.version, files: t};
    }

}

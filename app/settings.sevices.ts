/**
 * Created by weijian on 2016/10/24.
 */

import {Injectable} from "@angular/core";
import {remote} from "electron";
import * as path from "path";

@Injectable()
export class SettingsService {

    static SETTING_LIBRARY = "library";
    static defaultLibraries = [
        {
            "default": true,
            path: path.join(remote.app.getPath("appData"), "library")
        },
    ];
    libraries: {"default": boolean,path: string}[];


    getLibraries() {
        if (!this.libraries) {
            let data = localStorage.getItem(SettingsService.SETTING_LIBRARY);
            if (!data) {
                this.libraries = SettingsService.defaultLibraries;
                localStorage.setItem(SettingsService.SETTING_LIBRARY,
                    JSON.stringify(SettingsService.defaultLibraries));
            } else {
                this.libraries = JSON.parse(data);
            }
        }
        return this.libraries;
    }

    getDefaultLibrary() {
        if (!this.libraries) {
            this.getLibraries()
        }
        return this.libraries.find((item)=>item.default === true);
    }

    static SETTING_LOCALE = "locale";
    static defaultLocale = remote.app.getLocale();
    locale: string;

    getLocale(): string {
        if (!this.locale) {
            let locale = localStorage.getItem(SettingsService.SETTING_LOCALE);
            if (!locale) {
                this.locale = SettingsService.defaultLocale;
                localStorage.setItem(SettingsService.SETTING_LOCALE, SettingsService.defaultLocale);
            } else {
                this.locale = locale;
            }
        }
        return this.locale;
    }

    setLocale(locale: string) {
        this.locale = locale;
        localStorage.setItem(SettingsService.SETTING_LOCALE, locale);
    }
}
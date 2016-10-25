/**
 * Created by weijian on 2016/10/24.
 */

import {Injectable} from "@angular/core";
@Injectable()
export class SettingsService {

    static SETTING_LIBRARY = "library";
    libraries: [{selected: boolean,path: string}];

    getLibraries() {
        if (!this.libraries) {
            let data = localStorage.getItem(SettingsService.SETTING_LIBRARY);
            this.libraries = JSON.parse(data);
        }
        return this.libraries;
    }

    getDefaultLibrary() {
        if (!this.libraries) {
            this.getLibraries()
        }
        return this.libraries.find((item)=>item.selected === true);
    }

    static SETTING_LOCALE = "locale";
    locale: string;

    getLocale(): string {
        if (!this.locale) {
            this.locale = localStorage.getItem(SettingsService.SETTING_LOCALE);
        }
        return this.locale;
    }

    setLocal(locale: string) {
        this.locale = locale;
        localStorage.setItem(SettingsService.SETTING_LOCALE, locale);
    }
}
import {TRANSLATIONS, TRANSLATIONS_FORMAT, LOCALE_ID} from "@angular/core";
import {remote} from "electron";

export async function getTranslationProviders(): Promise<Object[]> {
    let locale = localStorage.getItem('locale');
    if (!locale) {
        locale = remote.app.getLocale();
        localStorage.setItem('locale', locale);
    }
    const noProviders: Object[] = [];
    if (!locale || locale === 'zh-CN') {
        return noProviders;
    }
    const translationFile = `./locale/messages.${locale}.xlf`;
    try {
        let translations = await getTranslationsWithSystemJs(translationFile);
        return [
            {provide: TRANSLATIONS, useValue: translations},
            {provide: TRANSLATIONS_FORMAT, useValue: 'xlf'},
            {provide: LOCALE_ID, useValue: locale}
        ]
    } catch (error) {
        return noProviders
    }
}
declare var System: any;
function getTranslationsWithSystemJs(file: string) {
    return System.import(file + '!text'); // relies on text plugin
}

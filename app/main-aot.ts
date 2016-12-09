import {MyCardNgFactory} from "../aot/app/mycard.module.ngfactory";
import {getTranslationProviders} from "./i18n-providers";
import {enableProdMode} from "@angular/core";
import {platformBrowser} from "@angular/platform-browser";
enableProdMode();

getTranslationProviders().then(providers => {
    const options = {providers};
    platformBrowser().bootstrapModuleFactory(MyCardNgFactory);
});

import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {getTranslationProviders} from './i18n-providers';
import {MyCard} from './mycard.module';

getTranslationProviders().then(providers => {
    const options = {providers};
    platformBrowserDynamic().bootstrapModule(MyCard, options);
});

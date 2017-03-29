import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {getTranslationProviders} from './i18n-providers';
import {MoeCube} from './moecube.module';

getTranslationProviders().then(providers => {
    const options = {providers};
    platformBrowserDynamic().bootstrapModule(MoeCube, options);
});

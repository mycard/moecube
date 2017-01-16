window['jQuery'] = require('jquery');
window['Tether'] = require('tether');
import 'node_modules/bootstrap/dist/js/bootstrap.min.js';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {getTranslationProviders} from './i18n-providers';
import {MyCard} from './mycard.module';

getTranslationProviders().then(providers => {
    const options = {providers};
    platformBrowserDynamic().bootstrapModule(MyCard, options);
});

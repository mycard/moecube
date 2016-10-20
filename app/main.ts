import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { MyCard } from './mycard.module';
import {enableProdMode} from '@angular/core';
enableProdMode();
platformBrowserDynamic().bootstrapModule(MyCard);

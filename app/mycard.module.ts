import {NgModule, NO_ERRORS_SCHEMA, LOCALE_ID} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {HttpModule} from '@angular/http';
import {MyCardComponent} from './mycard.component';
import {LoginComponent} from './login.component';
import {StoreComponent} from './store.component';
import {LobbyComponent} from './lobby.component';
import {AppDetailComponent} from './app-detail.component';
import {RosterComponent} from './roster.component';
import {YGOProComponent} from './ygopro.component';
import {AppsService} from './apps.service';
import {SettingsService} from './settings.sevices';
import {LoginService} from './login.service';
import {DownloadService} from './download.service';
import {AboutComponent} from './about.component';
import {CandyComponent} from './candy.component';

@NgModule({
    imports: [BrowserModule, FormsModule, ReactiveFormsModule, HttpModule],
    declarations: [
        MyCardComponent, LoginComponent, StoreComponent, LobbyComponent,
        AppDetailComponent, RosterComponent, YGOProComponent, AboutComponent, CandyComponent
    ],
    bootstrap: [MyCardComponent],
    providers: [
        AppsService, SettingsService, LoginService, DownloadService, {
            provide: LOCALE_ID,
            deps: [SettingsService],
            useFactory: (settingsService: SettingsService) => settingsService.getLocale()
        }
    ],
    schemas: [NO_ERRORS_SCHEMA]
})
export class MyCard {
}

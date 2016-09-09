import {NgModule, NO_ERRORS_SCHEMA}      from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {FormsModule} from '@angular/forms';
import {HttpModule}    from '@angular/http';

import {MyCardComponent}  from './mycard.component';
import {LoginComponent} from './login.component';
import {StoreComponent} from './store.component';
import {LobbyComponent} from './lobby.component';
import {AppsComponent} from './apps.component';
import {AppDetailComponent} from './app-detail.component';
import {RosterComponent} from './roster.component';
import {CandyComponent} from './candy.component';
import {CommunityComponent} from './community.component';

import {RoutingService} from './routing.service';
import {AppsService} from './apps.service';

import {TranslateModule} from 'ng2-translate/ng2-translate';

@NgModule({
    imports: [BrowserModule, FormsModule, HttpModule, TranslateModule.forRoot()],
    declarations: [MyCardComponent, LoginComponent, StoreComponent, LobbyComponent, CommunityComponent, AppsComponent, AppDetailComponent, RosterComponent, CandyComponent],
    bootstrap: [MyCardComponent],
    providers: [RoutingService, AppsService],
    schemas: [NO_ERRORS_SCHEMA]
})
export class MyCard {
}
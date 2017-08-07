import {NgModule, NO_ERRORS_SCHEMA} from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { CandyComponent } from './candy/candy.component';
import { MyCardRoutingModule } from './mycard-routing.module';
import { MyCardComponent } from './mycard/mycard.component';
import { NavbarComponent } from './navbar/navbar.component';
import { SplitPaneModule } from 'ng2-split-pane/lib/ng2-split-pane';
import { LobbyComponent } from './lobby/lobby.component';
import { AppDetailComponent } from './app-detail/app-detail.component';
import { NetworkComponent } from './network/network.component';
import { RosterComponent } from './roster/roster.component';
import { YGOProComponent } from './ygopro/ygopro.component';

import 'rxjs/Rx';
import {AppsService} from './apps.service';
import {DownloadService} from './download.service';
import {LoginService} from './login.service';
import {SettingsService} from './settings.service';
import {FormsModule} from '@angular/forms';
import {HttpModule} from '@angular/http';
import { LoginComponent } from './login/login.component';
import { CommunityComponent } from './community/community.component';

@NgModule({
  declarations: [
    MyCardComponent,
    CandyComponent,
    NavbarComponent,
    LobbyComponent,
    AppDetailComponent,
    NetworkComponent,
    RosterComponent,
    YGOProComponent,
    LoginComponent,
    CommunityComponent
  ],
  imports: [
    BrowserModule,
    MyCardRoutingModule,
    SplitPaneModule,
    FormsModule,
    HttpModule
  ],
  providers: [AppsService, DownloadService, LoginService, SettingsService],
  bootstrap: [MyCardComponent],
  schemas: [NO_ERRORS_SCHEMA]
})
export class MyCardModule {
}

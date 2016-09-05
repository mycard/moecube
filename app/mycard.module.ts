import { NgModule }      from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { MyCardComponent }  from './mycard.component';
import { LoginComponent } from './login.component';
import { StoreComponent } from './store.component';
import { LobbyComponent } from './lobby.component';
import { AppsComponent } from './apps.component';
import { AppDetailComponent } from './app-detail.component';
import { RosterComponent } from './roster.component';
import { CandyComponent } from './candy.component';
import { CommunityComponent } from './community.component';

import { RoutingService } from './routing.service';


@NgModule({
  imports:      [ BrowserModule ],
  declarations: [ MyCardComponent, LoginComponent, StoreComponent, LobbyComponent, CommunityComponent, AppsComponent, AppDetailComponent, RosterComponent, CandyComponent ],
  bootstrap:    [ MyCardComponent ],
  providers:    [ RoutingService ],
})
export class MyCard { }
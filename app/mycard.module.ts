import { NgModule }      from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpModule }    from '@angular/http';

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
import { AppsService } from './apps.service';


@NgModule({
  imports:      [ BrowserModule,HttpModule ],
  declarations: [ MyCardComponent, LoginComponent, StoreComponent, LobbyComponent, CommunityComponent, AppsComponent, AppDetailComponent, RosterComponent, CandyComponent ],
  bootstrap:    [ MyCardComponent ],
  providers:    [ RoutingService, AppsService ],
})
export class MyCard { }
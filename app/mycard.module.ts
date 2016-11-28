import {NgModule, NO_ERRORS_SCHEMA} from "@angular/core";
import {BrowserModule} from "@angular/platform-browser";
import {FormsModule, ReactiveFormsModule} from "@angular/forms";
import {HttpModule} from "@angular/http";
import {MyCardComponent} from "./mycard.component";
import {LoginComponent} from "./login.component";
import {StoreComponent} from "./store.component";
import {LobbyComponent} from "./lobby.component";
import {AppDetailComponent} from "./app-detail.component";
import {RosterComponent} from "./roster.component";
import {CommunityComponent} from "./community.component";
import {YGOProComponent} from "./ygopro.component";
import {AppsService} from "./apps.service";
import {SettingsService} from "./settings.sevices";
import {LoginService} from "./login.service";
import {DownloadService} from "./download.service";
import {InstallService} from "./install.service";

@NgModule({
    imports: [BrowserModule, FormsModule, ReactiveFormsModule, HttpModule],
    declarations: [
        MyCardComponent, LoginComponent, StoreComponent, LobbyComponent,
        CommunityComponent, AppDetailComponent, RosterComponent, YGOProComponent,
    ],
    bootstrap: [MyCardComponent],
    providers: [
        AppsService, SettingsService, LoginService, DownloadService,
        InstallService
    ],
    schemas: [NO_ERRORS_SCHEMA]
})
export class MyCard {
}
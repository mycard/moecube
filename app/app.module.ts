import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpModule } from '@angular/http';
import { BrowserModule } from '@angular/platform-browser';
import { ELECTRON_SCHEMA } from 'electron-schema';
import { CandyComponent } from './candy/candy.component';
import { CommunityComponent } from './community/community.component';
import { CubeAchievementsComponent } from './cube-achievements/cube-achievements.component';
import { CubeActionsComponent } from './cube-actions/cube-actions.component';
import { CubeArenaComponent } from './cube-arena/cube-arena.component';
import { CubeDescriptionComponent } from './cube-description/cube-description.component';
import { CubeDetailComponent } from './cube-detail/cube-detail.component';
import { CubeExpansionsComponent } from './cube-expansions/cube-expansions.component';
import { CubeNewsComponent } from './cube-news/cube-news.component';
import { CubesService } from './cubes.service';
import { DownloadService } from './download.service';
import { LobbyComponent } from './lobby/lobby.component';
import { LoginService } from './login.service';
import { LoginComponent } from './login/login.component';
import { MaotamaComponent } from './maotama/maotama.component';
import { MoeCubeComponent } from './moecube/moecube.component';
import { ProfileComponent } from './profile/profile.component';
import { ProgressBarComponent } from './progress-bar/progress-bar.component';
import { ProgressSpinnerComponent } from './progress-spinner/progress-spinner.component';
import { RosterComponent } from './roster/roster.component';
import { RoutingService } from './routing.sevices';
import { SettingsService } from './settings.sevices';
import { UpdateComponent } from './update/update.component';
import { WindowControlComponent } from './window-control/window-control.component';
import { YGOProComponent } from './ygopro/ygopro.component';

@NgModule({
  imports: [BrowserModule, FormsModule, ReactiveFormsModule, HttpModule],
  declarations: [
    MoeCubeComponent, LoginComponent, LobbyComponent,
    CubeDetailComponent, RosterComponent, YGOProComponent, CandyComponent,
    ProgressSpinnerComponent, CommunityComponent, UpdateComponent, WindowControlComponent,
    CubeActionsComponent, CubeArenaComponent, CubeDescriptionComponent, CubeNewsComponent, CubeExpansionsComponent,
    ProgressBarComponent, MaotamaComponent, ProfileComponent, CubeAchievementsComponent
  ],
  bootstrap: [MoeCubeComponent],
  providers: [
    CubesService, SettingsService, LoginService, DownloadService, RoutingService
    // , AuthGuard, LoadingGuard,
    // 执行 xi18n 的时候注释掉这几行
    // , {
    //   provide: LOCALE_ID,
    //   deps: [SettingsService],
    //   useFactory: (settingsService: SettingsService) => settingsService.getLocale()
    // }
  ],
  schemas: [ELECTRON_SCHEMA]
})
export class AppModule {
}

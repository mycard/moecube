import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './auth.guard';
import { CommunityComponent } from './community/community.component';
import { CubeDetailComponent } from './cube-detail/cube-detail.component';
import { LoadingGuard } from './loading.guard';
import { LobbyComponent } from './lobby/lobby.component';
import { LoginComponent } from './login/login.component';
import { ProfileComponent } from './profile/profile.component';

const routes: Routes = [
  { path: '', redirectTo: '/lobby', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'community', component: CommunityComponent },
  { path: 'profile', component: ProfileComponent },
  {
    path: 'lobby',
    component: LobbyComponent,
    canActivate: [AuthGuard],
    children: [
      { path: ':id', component: CubeDetailComponent, canActivate: [LoadingGuard] }
    ]
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes, { useHash: true })],
  exports: [RouterModule]
})
export class AppRoutingModule {
}

import { Component, OnInit } from '@angular/core';
import { remote } from 'electron';
import { LoginService } from '../login.service';
import { SettingsService } from '../settings.sevices';

@Component({

  selector: 'moecube',
  templateUrl: './moecube.component.html',
  styleUrls: ['./moecube.component.css'],

})
export class MoeCubeComponent implements OnInit {
  locale: string;

  currentPage = 'lobby';

  constructor(public loginService: LoginService, private settingsService: SettingsService) {
  }

  ngOnInit() {
    this.locale = this.settingsService.getLocale();
  }

  submit() {
    if (this.locale !== this.settingsService.getLocale()) {
      localStorage.setItem(SettingsService.SETTING_LOCALE, this.locale);
      remote.app.relaunch();
      remote.app.quit();
    }
  }
}

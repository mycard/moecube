import { ChangeDetectorRef, Component, ElementRef, OnInit, Renderer, ViewChild } from '@angular/core';
import 'bootstrap';
import { remote, shell } from 'electron';
import * as $ from 'jquery';
import * as Tether from 'tether';
import { LoginService } from '../login.service';
import { SettingsService } from '../settings.service';
window['Tether'] = Tether;

const autoUpdater: Electron.AutoUpdater = remote.getGlobal('autoUpdater');

@Component({
  selector: 'mycard-root',
  templateUrl: './mycard.component.html',
  styleUrls: ['./mycard.component.css']
})
export class MyCardComponent implements OnInit {
  currentPage = 'lobby';

  update_status: string | undefined = remote.getGlobal('update_status');
  update_error: string | undefined;
  currentWindow = remote.getCurrentWindow();
  window = window;

  @ViewChild('error')
  error: ElementRef;
  @ViewChild('checking_for_update')
  checking_for_update: ElementRef;
  @ViewChild('update_available')
  update_available: ElementRef;
  @ViewChild('update_downloaded')
  update_downloaded: ElementRef;
  update_elements: Map<string, ElementRef>;

  locale: string;

  resizing: HTMLElement | null;

  @ViewChild('moesound')
  moesound: ElementRef;

  platform = process.platform

  ngOnInit() {
    this.update_elements = new Map(Object.entries({
      'error': this.error,
      'checking-for-update': this.checking_for_update,
      'update-available': this.update_available,
      'update-downloaded': this.update_downloaded
    }));
    // document.addEventListener('drop', (event)=>{
    //     console.log('drop', event);
    //     event.preventDefault();
    //
    // });
  }

  constructor(private renderer: Renderer, public loginService: LoginService, private ref: ChangeDetectorRef,
              private settingsService: SettingsService) {
    // renderer.listenGlobal('window', 'message', (event) => {
    //     console.log(event);
    //     // Do something with 'event'
    // });

    this.currentWindow.on('maximize', () => this.ref.detectChanges());
    this.currentWindow.on('unmaximize', () => this.ref.detectChanges());

    autoUpdater.on('error', (error) => {
      this.set_update_status('error');
    });
    autoUpdater.on('checking-for-update', () => {
      this.set_update_status('checking-for-update');
    });
    autoUpdater.on('update-available', () => {
      this.set_update_status('update-available');
    });
    autoUpdater.on('update-not-available', () => {
      this.set_update_status('update-not-available');
    });
    autoUpdater.on('update-downloaded', (event) => {
      this.set_update_status('update-downloaded');
    });

    this.locale = this.settingsService.getLocale();

  }

  update_retry() {
    autoUpdater.checkForUpdates();
  }

  update_install() {
    autoUpdater.quitAndInstall();
  }

  set_update_status(status: string) {
    console.log('autoUpdater', status);
    if (this.update_status) {
      const element = this.update_elements.get(this.update_status);
      if (element) {
        $(element.nativeElement).tooltip('dispose');
      }
    }
    this.update_status = status;
    this.ref.detectChanges();

    const element = this.update_elements.get(this.update_status);
    if (element) {
      $(element.nativeElement).tooltip({ placement: 'bottom', container: 'body' });
    }
  }

  openExternal(url: string) {
    shell.openExternal(url);
  }

  submit() {
    if (this.locale !== this.settingsService.getLocale()) {
      localStorage.setItem(SettingsService.SETTING_LOCALE, this.locale);
      remote.app.relaunch();
      remote.app.quit();
    }
  }

  //
  // moesound_loaded() {
  //     this.moesound.nativeElement.insertCSS(`
  //         body > section > header, #bjax-target > div.row.m-t-lg.m-b-lg, #bjax-target > section {
  //             display: none;
  //         }
  //         body > section > section {
  //             top: 0!important;
  //         }
  //     `);
  // }
  //
  // moesound_newwindow(url: string) {
  //     console.log(url);
  // }
}

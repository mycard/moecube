/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, OnInit } from '@angular/core';
import { remote } from 'electron';


@Component({
  selector: 'update',
  templateUrl: './update.component.html',
  styleUrls: ['./update.component.css'],
})
export class UpdateComponent implements OnInit {

  status: string;
  error: string;
  readonly autoUpdater: Electron.AutoUpdater = remote.getGlobal('autoUpdater');

  ngOnInit() {
    this.autoUpdater.on('error', (error) => {
      this.status = 'error';
    });
    this.autoUpdater.on('checking-for-update', () => {
      this.status = 'checking-for-update';
    });
    this.autoUpdater.on('update-available', () => {
      this.status = 'update-available';
    });
    this.autoUpdater.on('update-not-available', () => {
      this.status = 'update-not-available';
    });
    this.autoUpdater.on('update-downloaded', () => {
      this.status = 'update-downloaded';
    });
  }

  retry() {
    this.autoUpdater.checkForUpdates();
  }

  install() {
    this.autoUpdater.quitAndInstall();
  }
}

/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, OnDestroy, OnInit } from '@angular/core';
import { remote } from 'electron';

@Component({
  selector: 'update',
  templateUrl: './update.component.html',
  styleUrls: ['./update.component.css'],
})
export class UpdateComponent implements OnInit, OnDestroy {

  autoUpdater: Electron.AutoUpdater = remote.getGlobal('autoUpdater');
  events = new Map<string, Function>();
  status: string;
  error: string;

  ngOnInit() {
    for (let event of ['error', 'checking-for-update', 'update-available', 'update-not-available', 'update-downloaded']) {
      const listener = () => this.status = event;
      this.autoUpdater.on(event, listener);
      this.events.set(event, listener);
    }
    window.addEventListener('unload', () => this.ngOnDestroy());
  }

  ngOnDestroy() {
    for (let [event, listener] of this.events) {
      this.autoUpdater.removeListener(event, listener);
    }
    this.events.clear();
  }
}

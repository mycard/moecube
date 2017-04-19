import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { remote } from 'electron';

@Component({
  selector: 'window-control',
  templateUrl: './window-control.component.html',
  styleUrls: ['./window-control.component.css']
})
export class WindowControlComponent implements OnInit {

  readonly currentWindow = remote.getCurrentWindow();

  constructor(private ref: ChangeDetectorRef) {
  }

  ngOnInit() {
    this.currentWindow.on('maximize', () => this.ref.detectChanges());
    this.currentWindow.on('unmaximize', () => this.ref.detectChanges());
  }
}

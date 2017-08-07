import {Component, Input} from '@angular/core';
import {clipboard} from 'electron';
import {App} from '../app';
import {AppsService} from '../apps.service';


@Component({
  selector: 'mycard-network',
  templateUrl: './network.component.html',
  styleUrls: ['./network.component.css']
})
export class NetworkComponent {
  clipboard = clipboard;

  @Input()
  currentApp: App;

  constructor(public appsService: AppsService) {
    console.log('constructor');
  }
}

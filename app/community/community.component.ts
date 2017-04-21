/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';
import { shell } from 'electron';
import { RoutingService } from '../routing.sevices';

@Component({
  selector: 'webview[community]',
  template: '',
  styleUrls: ['./community.component.css'],
  host: { '[src]': 'routingService.currentCommunityURL', '(new-window)': 'shell.openExternal($event.url)' }
})
export class CommunityComponent {

  public shell = shell;

  constructor(public routingService: RoutingService) {
  }
}

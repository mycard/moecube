/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';
import { shell } from 'electron';

@Component({
  selector: 'community',
  templateUrl: './community.component.html',
  styleUrls: ['./community.component.css'],
})
export class CommunityComponent {
  openExternal(url: string) {
    shell.openExternal(url);
  }
}

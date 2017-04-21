/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';

declare const URLSearchParams: any;


@Component({
  selector: 'webview[profile]',
  template: '',
  styleUrls: ['./profile.component.css'],
  host: { 'src': 'https://accounts.moecube.com/profiles', '(new-window)': 'openExternal($event.url)' }

})
export class ProfileComponent {
}

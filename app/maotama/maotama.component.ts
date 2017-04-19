/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';
import { clipboard } from 'electron';

@Component({
  selector: 'maotama',
  templateUrl: './maotama.component.html',
  styleUrls: ['./maotama.component.css'],
})
export class MaotamaComponent {
  copy(text: string) {
    clipboard.writeText(text);
  }
}

/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input } from '@angular/core';

@Component({
  selector: 'progress-bar',
  templateUrl: './progress-bar.component.html',
  styleUrls: ['./progress-bar.component.css'],
})
export class ProgressBarComponent {

  @Input()
  value?: number;

}

/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input } from '@angular/core';

@Component({
  selector: 'progress-spinner',
  templateUrl: './progress-spinner.component.html',
  styleUrls: ['./progress-spinner.component.css'],
})
export class ProgressSpinnerComponent {

  @Input()
  value?: number;

}

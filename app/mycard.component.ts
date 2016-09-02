import { Component } from '@angular/core';
declare var process;
@Component({
  selector: 'mycard',
  templateUrl: 'app/mycard.component.html',
  styleUrls: ['app/mycard.component.css'],

})

export class MyCardComponent {
  platform = process.platform;
}

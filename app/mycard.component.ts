import { Component } from '@angular/core';
declare var process;
import { RoutingService } from './routing.service';
@Component({
  selector: 'mycard',
  templateUrl: 'app/mycard.component.html',
  styleUrls: ['app/mycard.component.css'],

})

export class MyCardComponent {
  platform = process.platform;
  constructor(private routingService: RoutingService) { }
}

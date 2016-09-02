import { Component } from '@angular/core';
import { RoutingService } from './routing.service';
@Component({
  selector: 'mycard',
  templateUrl: 'app/mycard.component.html',
  styleUrls: ['app/mycard.component.css'],
})
export class MyCardComponent {
  constructor(private routingService: RoutingService) { }
}

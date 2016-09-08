import { Component } from '@angular/core';
import {RoutingService} from "./routing.service";
@Component({
    selector: '#candy',
    templateUrl: 'app/candy.component.html',
    styleUrls: ['app/candy.component.css'],
})
export class CandyComponent {
    constructor(private routingService: RoutingService){

    }
}

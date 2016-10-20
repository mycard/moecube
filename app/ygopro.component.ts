/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from '@angular/core';
import {AppsService} from "./apps.service";
import {RoutingService} from "./routing.service";

declare var System;
const fs = System._nodeRequire('fs');

@Component({
    selector: 'ygopro',
    templateUrl: 'app/ygopro.component.html',
    styleUrls: ['app/ygopro.component.css'],
})
export class YGOProComponent {
    constructor(private appsService: AppsService, private routingService: RoutingService) {
    }
    decks () {
        return new Promise(()=>{
            fs.readdir()
        })
    }
}

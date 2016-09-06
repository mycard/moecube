import {Component} from '@angular/core';
declare var process;
declare var System;
import {RoutingService} from './routing.service';
const electron = System._nodeRequire('electron');


@Component({
    selector: 'mycard',
    templateUrl: 'app/mycard.component.html',
    styleUrls: ['app/mycard.component.css'],

})

export class MyCardComponent {
    platform = process.platform;

    constructor(private routingService: RoutingService) {
    }

    changeFouce(component) {
        this.routingService.component = component;
    }
    refresh() {
        electron.remote.getCurrentWindow().reload()
    }
}

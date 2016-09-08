import {Component, Renderer} from '@angular/core';
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

    constructor(private routingService: RoutingService, private renderer: Renderer) {
        renderer.listenGlobal('window', 'message', (event) => {
            console.log(event);
            // Do something with 'event'
        });
    }

    changeFouce(component) {
        this.routingService.component = component;
    }
    refresh() {
        electron.remote.getCurrentWindow().reload()
    }
}

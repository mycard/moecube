import { Component } from '@angular/core';
import { AppsService } from './apps.service'
import { RoutingService } from './routing.service'

//import 'rxjs/Rx';
import {App} from "./app";
@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
})
export class AppDetailComponent {

    _currentApp;
    get currentApp(): App {

        let data = this.appsService.data;
        let tmp;
        if(data) {
            tmp = data.find((v)=>v.id === this.routingService.app);
            return tmp;
        } else {
        }
    }

    _name;
    get name() {
        if(this.currentApp) {
            return this.currentApp.name[this.currentApp.locales[0]];
        }
        return "Loading";
    };

    _isInstalled;
    get isInstalled() {
        if(this.currentApp) {
            if(this.currentApp.local.path) {
                return true;
            }
        }
        return false;
    }


    constructor(private appsService: AppsService, private routingService: RoutingService ) {
    }

}

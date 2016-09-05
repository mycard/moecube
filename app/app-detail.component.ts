import { Component } from '@angular/core';
import { AppsService } from './apps.service'
import { RoutingService } from './routing.service'
@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
})
export class AppDetailComponent {
    name() {
        if(this.appsService.detail[this.routingService.app])
        {
            return this.appsService.detail[this.routingService.app].name;
        } else {
            return this.appsService.detail["default"].name;
        }
    };

    isInstalled() {
        if(this.appsService.detail[this.routingService.app])
        {
            return this.appsService.detail[this.routingService.app].isInstalled;
        } else {
            return this.appsService.detail["default"].isInstalled;
        }
    }

    constructor(private appsService: AppsService, private routingService: RoutingService ) {
    }

}

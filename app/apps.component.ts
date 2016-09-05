import { Component } from '@angular/core';
import { AppsService } from './apps.service'
import { RoutingService } from './routing.service'

@Component({
    selector: 'apps',
    templateUrl: 'app/apps.component.html',
    styleUrls: ['app/apps.component.css'],
})
export class AppsComponent {

    constructor(private appsService: AppsService, private routingService: RoutingService ) {
        appsService.getApps();
    }

    selectApp(id) {
        this.routingService.app = id;
        this.getDetail();
    }

    getDetail() {
        for(let i = 0; i < this.appsService.data.length; i++){
            let x = this.appsService.data[i];
            if(x.id == this.routingService.app) {
                this.appsService.detail[this.routingService.app] = x;
            }
        }
        console.log(this.appsService.detail);
    }
}

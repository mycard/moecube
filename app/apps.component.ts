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
        appsService.getApps(()=>{
            console.log(appsService.data)
            if(appsService.data.length > 0) {
                this.selectApp(appsService.data[0].id);
                let tmp = this.appsService.data.filter((v)=>v.id === this.routingService.app);
                console.log(tmp);
            }
        });
    }

    selectApp(id) {
        this.routingService.app = id;
    }

}

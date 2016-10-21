import {Component} from '@angular/core';
import {AppsService} from './apps.service'
import {RoutingService} from './routing.service'

@Component({
    selector: 'apps',
    templateUrl: 'app/apps.component.html',
    styleUrls: ['app/apps.component.css'],
})
export class AppsComponent {

    constructor(private appsService: AppsService, private routingService: RoutingService) {
        appsService.getApps(()=> {
            //console.log(appsService.data)
            if (appsService.data.length > 0) {
                this.selectApp(appsService.data[0].id);
                let tmp = this.appsService.data.filter((v)=>v.id === this.routingService.app);
                //console.log(tmp);
            }
        });
    }

    _apps;
    get apps() {
        let contains = ["game", "music", "book"];

        let data = this.appsService.data;
        let apps;

        if (data) {
            apps = this.appsService.data.filter((app)=> {
                return contains.includes(app.category);
            });
        }

        return apps || [];
    }

    selectApp(id) {
        this.routingService.app = id;
        this.appsService.createInstallConfig(id);
    }

    get grouped_apps() {
        let result = {'installed': [], 'not_installed': []};

        for (let app of this.apps) {
            if (app.local) {
                result.installed.push(app)
            } else {
                result.not_installed.push(app)
            }
        }
        return result
    }

}

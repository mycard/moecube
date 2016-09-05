/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';
import { AppsService } from './apps.service'
@Component({
    selector: 'apps',
    templateUrl: 'app/apps.component.html',
    styleUrls: ['app/apps.component.css'],
})
export class AppsComponent {
    data = '';

    constructor(private appsService: AppsService) {
        appsService.getApps();
        //this.data = appsService.data;
    }

}

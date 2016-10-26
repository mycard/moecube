import {Component, OnInit} from "@angular/core";
import {AppsService} from "./apps.service";
import {App} from "./app";

@Component({
    selector: 'apps',
    templateUrl: 'app/apps.component.html',
    styleUrls: ['app/apps.component.css'],
})
export class AppsComponent implements OnInit {

    constructor(private appsService: AppsService) {
    }

    ngOnInit() {

    }

    chooseApp(app: App) {
        this.appsService.currentApp = app;
    }

    get grouped_apps() {
        let contains = ["game", "music", "book"];
        let apps = Array.from(this.appsService.allApps.values());
        let result = {};
        for (let app of apps) {
            if (contains.includes(app.category)) {
                let tag;
                if (app.local) {
                    tag = 'installed';
                } else {
                    tag = app.tags[0];
                }
                if (!result[tag]) {
                    result[tag] = []
                }
                result[tag].push(app)
            }
        }
        //console.log(result)
        return result
    }
}
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
        let result = {'installed': []};
        for (let app of apps) {
            if (contains.includes(app.category)) {
                if (app.local) {
                    result.installed.push(app)
                } else {
                    if (!result[app.tags[0]]) {
                        result[app.tags[0]] = []
                    }
                    result[app.tags[0]].push(app)
                }
            }
        }
        //console.log(result)
        return result
    }
}
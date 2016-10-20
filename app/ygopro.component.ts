/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from '@angular/core';
import {AppsService} from "./apps.service";
import {RoutingService} from "./routing.service";

declare var System;
const fs = System._nodeRequire('fs');
const path = System._nodeRequire('path');
const Promise = System._nodeRequire('bluebird');
Promise.resolve("foo").then(function (msg) {
    console.log(msg)
});

@Component({
    selector: 'ygopro',
    templateUrl: 'app/ygopro.component.html',
    styleUrls: ['app/ygopro.component.css'],
})
export class YGOProComponent {
    app = this.appsService.searchApp('ygopro');
    decks = [];

    constructor(private appsService: AppsService, private routingService: RoutingService) {
        this.refresh()
    }

    refresh() {
        this.get_decks().then((decks)=> {
            this.decks = decks;
        })
    }

    get_decks(): Promise<[string]> {
        return new Promise((resolve, reject)=> {
            fs.readdir(path.join(this.app.local.path, 'deck'), (error, files)=> {
                if (error) {
                    reject(error)
                } else {
                    let result: string[] = files.filter(file=>path.extname(file) == ".ydk").map(file=>path.basename(file, '.ydk'));
                    resolve(result);
                }
            })
        })
    }
}

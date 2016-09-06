import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';

@Injectable()
export class AppsService {
    data;

    detail = {
        "default": {
            "id": "id",
            "name": "name",
            "isInstalled": false
        },
    }

    constructor(private http: Http) {
    }

    getApps(callback) {
        this.http.get('./apps.json')
            .map(response => response.json())
            .subscribe(data => {
                this.data = data
                if(typeof(callback) === 'function') {
                    callback();
                }
            });

    }

}
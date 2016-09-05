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

    getApps() {
        this.http.get('./apps.json')
            .map(response => response.json())
            .subscribe(data => {console.log(data);this.data = data});

    }

}
import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';
import {App} from "./app";
import {AppLocal} from "./app-local";

@Injectable()
export class AppsService {
    data : App[];


    constructor(private http: Http) {
    }

    getApps(callback) {
        this.http.get('./apps.json')
            .map(response => {
                return response.json()
            })
            .subscribe(data => {
                this.data = data;
                //console.log(this.data);
                if(typeof(callback) === 'function') {
                    callback();
                }
            });
    }


}

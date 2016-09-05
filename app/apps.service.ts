import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';

@Injectable()
export class AppsService {
    constructor(private http: Http) {
    }

    data = '';


    getApps() {
        console.log(123);
        this.http.get('./apps.json')
            .map(response => response.json())
            .subscribe(data => this.data = data);
    }

}
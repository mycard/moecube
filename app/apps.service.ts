import { Injectable } from '@angular/core';
import { Http,Response } from '@angular/http';
//import { Observable } from 'rxjs';
//import 'rxjs/add/operator/map'
import 'rxjs/Rx';

@Injectable()
export class AppsService {
    constructor(private http: Http) {}
    data = '';



    getApps() {
        console.log(123);
        this.http.get('./apps.json').map((res) => {console.log(res)})//.subscribe(res => this.data = res);
    }

}
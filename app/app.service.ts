import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';
import {AppLocal} from "./app-local";

// declare var System;


@Injectable()
export class AppService {




    Aria2 = window['System']._nodeRequire('aria2');
    constructor(private http: Http) {
    }

    download() {
        const aria2 = new this.Aria2();
        console.log(aria2);
        aria2.open(()=>{
            //aria2.addUri(['http://thief.mycard.moe/metalinks/th13.meta4']);
        })

    }



}

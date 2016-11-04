/**
 * Created by weijian on 2016/10/26.
 */

import {Injectable, NgZone} from "@angular/core";
import {Http} from "@angular/http";
import {Observable} from "rxjs/Observable";
import {EventEmitter} from "events";
import {App} from "./app";
const Aria2 = require('aria2');


@Injectable()
export class DownloadService {
    aria2 = new Aria2();
    baseURL = 'http://thief.mycard.moe/metalinks/'
    appGidMap = new Map<App,string>();
    gidAppMap = new Map<string,App>();
    eventEmitter = new EventEmitter();

    open = this.aria2.open();

    constructor(private ngZone: NgZone, private http: Http) {
        this.aria2.onDownloadComplete = (gid)=> {
            let app = this.gidAppMap.get(gid.gid);
            if (app) {
                this.appGidMap.delete(app);
                this.gidAppMap.delete(gid.gid);
                this.eventEmitter.emit(app.id, 'complete');
            }
        }
    }

    getComplete(app: App): Promise<App> {
        if (this.appGidMap.has(app)) {
            return new Promise((resolve, reject)=> {
                this.eventEmitter.once(app.id, (event)=> {
                    resolve(app);
                })
            });
        }
    }

    getProgress(app: App): Observable<any> {
        let gid = this.appGidMap.get(app);
        return Observable.create((observer)=> {
            let interval;
            this.ngZone.runOutsideAngular(()=> {
                interval = setInterval(()=> {
                    this.aria2.tellStatus(gid).then((status: any)=> {
                        if (status.status === 'complete') {
                            observer.complete();
                        } else if (status.status === "active") {
                            observer.next({total: status.totalLength, progress: status.completedLength})
                        } else if (status.status === "error") {
                            observer.error(status.errorCode)
                        }
                    });
                }, 1000);
            });
            return ()=> {
                clearInterval(interval);
            }
        });
    }

    async addUris(apps: App[], path: string): Promise<App[]> {
        let tasks = [];
        for (let app of apps) {
            let task = await this.addUri(app, path);
            tasks.push(task);
        }
        return tasks;
    }

    async addUri(app: App, path: string): Promise<App> {
        let id = app.id;
        await this.open;
        if (this.appGidMap.has(app)) {
            return app;
        } else {
            let meta4link = `${this.baseURL}${id}.meta4`;
            let response = await this.http.get(meta4link).toPromise();
            let meta4 = btoa(response.text());
            let gid = (await this.aria2.addMetalink(meta4, {dir: path}))[0];
            this.appGidMap.set(app, gid);
            this.gidAppMap.set(gid, app);
            return app;
        }
    }
}

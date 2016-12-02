/**
 * Created by weijian on 2016/10/26.
 */
import {Injectable, NgZone, EventEmitter} from "@angular/core";
import {Http} from "@angular/http";
import {Observable} from "rxjs/Observable";
import {App} from "./app";
import {Observer} from "rxjs";
import Timer = NodeJS.Timer;
const Aria2 = require('aria2');

const MAX_LIST_NUM = 1000;
const ARIA2_INTERVAL = 1000;

export interface DownloadStatus {
    completedLength: string;
    downloadSpeed: string;
    gid: string;
    status: string;
    totalLength: string;
    errorCode: string;
    errorMessage: string;
}

@Injectable()
export class DownloadService {
    aria2 = new Aria2();
    open = this.aria2.open();
    updateEmitter = new EventEmitter<string>();
    progressList: Map<string,(Observable<any>)> = new Map();
    taskList: Map<string,DownloadStatus> = new Map();

    map: Map<string,string[]> = new Map();

    constructor(private ngZone: NgZone, private http: Http) {
        ngZone.runOutsideAngular(async() => {
            await this.open;
            setInterval(async() => {
                let activeList = await this.aria2.tellActive();
                let waitList = await this.aria2.tellWaiting(0, MAX_LIST_NUM);
                let stoppedList = await this.aria2.tellStopped(0, MAX_LIST_NUM);
                for (let item of activeList) {
                    this.taskList.set(item.gid, item);
                }
                for (let item of waitList) {
                    this.taskList.set(item.gid, item);
                }
                for (let item of stoppedList) {
                    this.taskList.set(item.gid, item);
                }
                this.updateEmitter.emit("updated");
            }, ARIA2_INTERVAL);
        })
    }

    private createId(): string {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }

        return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
            s4() + '-' + s4() + s4() + s4();
    }

    downloadProgress(id: string): Observable<any> {
        let progress = this.progressList.get(id);
        if (progress) {
            return progress;
        } else {
            return Observable.create((observer: Observer<any>) => {
                let status = '';
                let completedLength = 0;
                let totalLength = 0;
                let gidList = this.map.get(id) !;
                this.updateEmitter.subscribe((value: string) => {
                    let statusList = new Array(gidList.length);
                    let newCompletedLength = 0;
                    let newTotalLength = 0;
                    for (let [index,gid] of gidList.entries()) {
                        let task = this.taskList.get(gid)!;
                        statusList[index] = task.status;
                        newCompletedLength += parseInt(task.completedLength);
                        newTotalLength += parseInt(task.totalLength);
                    }
                    if (newCompletedLength !== completedLength || newTotalLength !== totalLength) {
                        completedLength = newCompletedLength;
                        totalLength = newTotalLength;
                        observer.next({status: status, completedLength: completedLength, totalLength: totalLength});
                    }
                    status = statusList.reduce((value, current) => {
                        if (value === "complete" && current === "complete") {
                            return "complete";
                        }
                        if (current != "complete" && current != "active") {
                            return "error";
                        }
                    });
                    if (status === "complete") {
                        observer.complete();
                    } else if (status == "error") {
                        observer.error("Download Error");
                    }
                    return () => {

                    }
                }, () => {

                }, () => {

                })
            });

        }
    }

    async getFile(id: string): Promise<string[]> {
        let gids = this.map.get(id)!;
        console.log('gids ', gids);
        let files: string[] = [];
        for (let gid of gids) {
            let file = await this.aria2.getFiles(gid);
            files.push(file[0].path);
        }
        return files;
    }

    async addMetalink(metalink: string, library: string): Promise<string> {
        let encodedMeta4 = new Buffer((metalink)).toString('base64');
        let gidList = await this.aria2.addMetalink(encodedMeta4, {dir: library});
        let taskId = this.createId();
        this.map.set(taskId, gidList);
        return taskId;
    }

    async addUri(url: string, destination: string): Promise<string> {
        await this.open;
        let id = await this.aria2.addUri([url], {dir: destination});
        return id;
    }

    async pause(id: string): Promise<void> {
        await this.open;
        try {
            await this.aria2.pause(id)
        } catch (e) {

        }
    }

}

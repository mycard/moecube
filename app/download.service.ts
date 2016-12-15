/**
 * Created by weijian on 2016/10/26.
 */
import {Injectable, NgZone, EventEmitter} from "@angular/core";
import {Http} from "@angular/http";
import {error} from "util";
import Timer = NodeJS.Timer;
const Logger = {
    "error": (message: string) => {
        console.error("DownloadService: ", message);
    }
};
const Aria2 = require('aria2');

const MAX_LIST_NUM = 1000;
const ARIA2_INTERVAL = 500;

export class DownloadStatus {
    completedLength: number;
    downloadSpeed: number;

    get downloadSpeedText(): string {
        if (!isNaN(this.downloadSpeed) && this.downloadSpeed !== 0) {
            const speedUnit = ["Byte/s", "KB/s", "MB/s", "GB/s", "TB/s"];
            let currentUnit = Math.floor(Math.log(this.downloadSpeed) / Math.log(1024));
            return (this.downloadSpeed / 1024 ** currentUnit).toFixed(1) + " " + speedUnit[currentUnit];
        }
        return "";
    };

    gid: string;
    status: string;
    totalLength: number;
    totalLengthText: string;
    errorCode: string;
    errorMessage: string;

    combine(...others: DownloadStatus[]): DownloadStatus {
        const priority = {
            undefined: -1,
            "": -1,
            "active": 0,
            "complete": 0,
            "paused": 1,
            "waiting": 1,
            "removed": 2,
            "error": 3
        };
        let status = Object.assign(new DownloadStatus(), this);
        for (let o of others) {
            if (priority[o.status] > priority[status.status]) {
                status.status = o.status;
                if (status.status === "error") {
                    status.errorCode = o.errorCode;
                    status.errorMessage = o.errorMessage;
                }
                status.downloadSpeed += o.downloadSpeed;
                status.totalLength += o.totalLength;
                status.completedLength += o.completedLength;
            }

        }
        return status;
    }

    // 0相等. 1不想等
    compareTo(other: DownloadStatus): number {
        if (this.status !== other.status ||
            this.downloadSpeed !== other.downloadSpeed ||
            this.completedLength !== other.completedLength ||
            this.totalLength !== other.totalLength) {
            return 1;
        } else {
            return 0;
        }
    }

    constructor(item ?: any) {
        if (item) {
            this.completedLength = parseInt(item.completedLength) || 0;
            this.downloadSpeed = parseInt(item.downloadSpeed) || 0;
            this.totalLength = parseInt(item.totalLength) || 0;
            this.gid = item.gid;
            this.status = item.status;
            this.errorCode = item.errorCode;
            this.errorMessage = item.errorMessage;
        } else {
            this.completedLength = 0;
            this.downloadSpeed = 0;
            this.totalLength = 0;
        }
    }
}

@Injectable()
export class DownloadService {
    // 强制指定IPv4，接到过一个反馈无法监听v6的。默认的host值是localhost，会连v6。
    aria2 = new Aria2({host: '127.0.0.1'});
    open = this.aria2.open();
    updateEmitter = new EventEmitter<void>();

    downloadList: Map<string,DownloadStatus> = new Map();

    taskMap: Map<string,string[]> = new Map();

    async refreshDownloadList() {
        let activeList = await this.aria2.tellActive();
        let waitList = await this.aria2.tellWaiting(0, MAX_LIST_NUM);
        let stoppedList = await this.aria2.tellStopped(0, MAX_LIST_NUM);
        this.downloadList.clear();
        for (let item of activeList) {
            this.downloadList.set(item.gid, new DownloadStatus(item));
        }
        for (let item of waitList) {
            this.downloadList.set(item.gid, new DownloadStatus(item));
        }
        for (let item of stoppedList) {
            this.downloadList.set(item.gid, new DownloadStatus(item));
        }
        this.updateEmitter.emit();
    }

    constructor(private ngZone: NgZone, private http: Http) {
        ngZone.runOutsideAngular(async() => {
            await this.open;
            setInterval(async() => {
                await this.refreshDownloadList();
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

    async progress(id: string, callback: (downloadStatus: DownloadStatus) => void) {
        return new Promise((resolve, reject) => {
            let gids = this.taskMap.get(id);
            if (gids) {
                let allStatus: DownloadStatus;
                let subscription = this.updateEmitter.subscribe(() => {

                    try {
                        let status: DownloadStatus = new DownloadStatus();
                        // 合并每个状态信息
                        status =
                            gids!.map((value, index, array) => {
                                let s = this.downloadList.get(value);
                                if (!s) {
                                    throw "Gid not exists";
                                }
                                return s;
                            })
                                .reduce((previousValue, currentValue, currentIndex, array) => {
                                    return previousValue.combine(currentValue);
                                }, status);
                        if (!allStatus) {
                            allStatus = status;
                        } else {
                            if (allStatus.compareTo(status) != 0) {
                                allStatus = status;
                            }
                        }
                        if (allStatus.status === "error") {
                            throw `Download Error: code ${allStatus.errorCode}, message: ${allStatus.errorMessage}`;
                        } else if (allStatus.status === "complete") {
                            resolve();
                            subscription.unsubscribe();
                        } else {
                            callback(allStatus);
                        }

                    } catch (e) {
                        reject(e);
                        subscription.unsubscribe();
                    }
                });
            } else {
                throw "Try to access invalid download id";
            }
        })
    }

    async getFiles(id: string): Promise<string[]> {
        let gids = this.taskMap.get(id)!;
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
        this.taskMap.set(taskId, gidList);
        // 每次添加任务，刷新一下本地任务列表
        await this.refreshDownloadList();
        return taskId;
    }

    async addUri(url: string, destination: string): Promise<string> {
        await this.open;
        let taskId = this.createId();
        let gid = await this.aria2.addUri([url], {dir: destination});
        this.taskMap.set(taskId, [gid]);
        return taskId;
    }

    async pause(id: string): Promise<void> {
        await this.open;
        try {
            await this.aria2.pause(id)
        } catch (e) {

        }
    }

}

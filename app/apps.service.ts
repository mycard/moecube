import {Injectable} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';
import {App} from "./app";
import {AppLocal} from "./app-local";

@Injectable()
export class AppsService {

    constructor(private http: Http) {
        let cc = "abdas19238d";
        this.downloads_info[cc] = 1;
    }

    fs = window['System']._nodeRequire('fs');
    path = window['System']._nodeRequire('path');
    mkdirp = window['System']._nodeRequire('mkdirp');
    electron = window['System']._nodeRequire('electron');
    Aria2 = window['System']._nodeRequire('aria2');

    data : App[];
    downloads_info = {};


    _download_dir;
    get download_dir() {
        const dir =  this.path.join(this.electron.remote.app.getAppPath(), 'cache');

        if(!this.fs.existsSync(dir)) {
            console.log('cache not exists');
            this.mkdirp(dir, (err)=>{
                if(err) {
                    console.error(err)
                } else {
                    console.log('create cache dir');
                }
            });
        }

        return dir;
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

    download(id, uri) {
        const aria2 = new this.Aria2();
        console.log(id);
        console.log(uri);
        let tmp_gid;
        aria2.open().then(()=>{
            aria2.addUri([uri], {'dir': this.download_dir}, (error, gid)=> {
                if(error) {
                    console.error(error);
                }
                console.log(gid);
                tmp_gid = gid;
            });
        });

        aria2.onDownloadComplete = (response)=>{
            console.log(response);
            aria2.tellStatus(tmp_gid, (err, res)=>{
                if(res.followedBy) {
                    this.downloads_info[id] = res.followedBy[0];
                }
                console.log(res);
            });

        };

    }

    getDownloadStatus(id) {
        let gid = this.downloads_info[id];
        console.log(this.downloads_info);

        let info = {};

        const aria2 = new this.Aria2();
        aria2.tellStatus(gid, (err, res)=>{
            console.log(res);
            info = res;
        });


        return info;


    }

}

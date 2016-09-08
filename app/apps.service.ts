import {Injectable, transition} from '@angular/core';
import {Http} from '@angular/http';
import 'rxjs/Rx';
import {App} from "./app";
import {AppLocal} from "./app-local";
import {TranslateService} from "ng2-translate";

@Injectable()
export class AppsService {

    constructor(private http: Http, private translate: TranslateService) {
        let loop = setInterval(()=> {
            this.aria2.tellActive().then((res)=> {
                console.log('res:', res);
                this.downloadsInfo = res;
            })
        }, 1000);

    }

    fs = window['System']._nodeRequire('fs');
    path = window['System']._nodeRequire('path');
    mkdirp = window['System']._nodeRequire('mkdirp');
    electron = window['System']._nodeRequire('electron');
    Aria2 = window['System']._nodeRequire('aria2');

    data: App[];
    downloadsInfo = {};


    aria2IsOpen = false;


    _aria2;
    get aria2() {
        if (!this._aria2) {
            this._aria2 = new this.Aria2();
            console.log("new aria2");
            this._aria2.onopen = ()=> {
                console.log('aria2 open');
            };
            this._aria2.onclose = ()=> {
                console.log('aria2 close');
                this.aria2IsOpen = false;
            };
            this._aria2.onDownloadComplete = (response)=> {
                console.log(response);
                //aria2.tellStatus(tmp_gid, (err, res)=>{
                //    if(res.followedBy) {
                //        this.downloadsInfo[id] = res.followedBy[0];
                //    }
                //    console.log(res);
                //});
            };
            this._aria2.onmessage = (m)=> {
                console.log('IN:', m);
                console.log('download infoi:', this.downloadsInfo);

            }
        }

        if (!this.aria2IsOpen) {
            this._aria2.open().then(()=> {
                console.log('aria2 websocket open')
                this.aria2IsOpen = true;
            });
        }

        return this._aria2;

    }

    _download_dir;
    get download_dir() {
        const dir = this.path.join(this.electron.remote.app.getAppPath(), 'cache');

        if (!this.fs.existsSync(dir)) {
            console.log('cache not exists');
            this.mkdirp(dir, (err)=> {
                if (err) {
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
            .subscribe((data) => {
                this.data = data;
                for (let app of data) {
                    //console.log(app)
                    for (let attribute of ['name', 'description']) {
                        if(!app[attribute]){continue} //这句应当是不需要的, 如果转换成了 App 类型, 应当保证一定有这些属性
                        for (let locale of Object.keys(app[attribute])) {
                            let result = {};
                            result[`app.${app['id']}.${attribute}`] = app[attribute][locale];
                            this.translate.setTranslation(locale, result, true);
                        }
                    }
                }
                //console.log(this.data);
                if (typeof(callback) === 'function') {
                    callback();
                }
            });
    }

    download(id, uri) {
        console.log(id);
        console.log(uri);
        let tmp_gid;
        this.aria2.addUri([uri], {'dir': this.download_dir}, (error, gid)=> {
            if (error) {
                console.error(error);
            }
            console.log(gid);
            tmp_gid = gid;
        });

    }

    getDownloadStatus(id) {

        let info = {};


        return info;


    }

}

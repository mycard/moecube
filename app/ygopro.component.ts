/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from '@angular/core';
import {AppsService} from "./apps.service";
import {RoutingService} from "./routing.service";

declare var process;
declare var System;
const fs = System._nodeRequire('fs');
const path = System._nodeRequire('path');
const child_process = System._nodeRequire('child_process');
//const Promise = System._nodeRequire('bluebird');
const ini = System._nodeRequire('ini');
const electron = System._nodeRequire('electron');

@Component({
    selector: 'ygopro',
    templateUrl: 'app/ygopro.component.html',
    styleUrls: ['app/ygopro.component.css'],
})
export class YGOProComponent {
    app = this.appsService.searchApp('ygopro');
    decks = [];
    current_deck;

    system_conf = path.join(this.app.local.path, 'system.conf');
    numfont = {'darwin': ['/System/Library/Fonts/PingFang.ttc']};
    textfont = {'darwin': ['/System/Library/Fonts/PingFang.ttc']};

    windbot = ["琪露诺", "谜之剑士LV4", "复制植物", "尼亚"];

    servers = [{address:"112.124.105.11", port: 7911}];

    constructor(private appsService: AppsService, private routingService: RoutingService) {
        this.refresh()
    }

    refresh = () => {
        this.get_decks().then((decks)=> {
            this.decks = decks;
            if (!(this.current_deck in this.decks)) {
                this.current_deck = decks[0];
            }
        })
    };

    get_decks(): Promise<[string]> {
        return new Promise((resolve, reject)=> {
            fs.readdir(path.join(this.app.local.path, 'deck'), (error, files)=> {
                if (error) {
                    reject(error)
                } else {
                    resolve(files.filter(file=>path.extname(file) == ".ydk").map(file=>path.basename(file, '.ydk')));
                }
            })
        })
    }

    get_font(files: string[]) {
        return new Promise((resolve, reject)=> {
            files.reduce((promise, file: string) => {
                return promise.then(()=>file).then(()=>new Promise((resolve, reject)=> {
                    fs.access(file, fs.constants.R_OK, (error) => {
                        error ? resolve(`can't find fonts ${files[process.platform]}`) : reject(file)
                    });
                }));
            }, Promise.resolve()).then(reject, resolve);
        })
    }

    edit_deck(deck) {
        this.load_system_conf()
            .then(this.fix_fonts)
            .then(data => {
                data['lastdeck'] = deck;
                return data
            })
            .then(this.save_system_conf)
            .then(()=>['-d'])
            .then(this.start_game)
            .catch(reason=>console.log(reason))
    }

    delete_deck(deck) {
        return new Promise((resolve, reject) => {
            fs.unlink(path.join(this.app.local.path, 'deck', deck + '.ydk'), resolve)
        }).then(this.refresh)
    }

    fix_fonts = (data) => {
        return this.get_font([data.numfont])
            .catch(() => this.get_font(this.numfont[process.platform]).then(font => data['numfont'] = font))
            .catch()
            .then(() => this.get_font([data.textfont.split(' ', 2)[0]]))
            .catch(() => this.get_font(this.textfont[process.platform]).then(font => data['textfont'] = `${font} 14`))
            .catch()
            .then(() => data)
    };

    load_system_conf = () => {
        return new Promise((resolve, reject)=> {
            fs.readFile(this.system_conf, {encoding: 'utf-8'}, (error, data) => {
                if (error) return reject(error);
                resolve(ini.parse(data));
            });
        })
    };

    save_system_conf = (data) => {
        return new Promise((resolve, reject)=> {
            fs.writeFile(this.system_conf, ini.stringify(data, {whitespace: true}), (error) => {
                if (error) return reject(error);
                resolve(data);
            });
        })
    };

    join(name, server) {
        this.load_system_conf()
            .then(this.fix_fonts)
            .then(data => {
                data['lastdeck'] = this.current_deck;
                data['lastip'] = server.address;
                data['lastport'] = server.port;
                data['roompass'] = name;
                return data
            })
            .then(this.save_system_conf)
            .then(()=>['-j'])
            .then(this.start_game)
            .catch(reason=>console.log(reason))
    };

    join_windbot(name) {
        this.join(name, this.servers[0])
    }

    start_game = (args) => {
        let win = electron.remote.getCurrentWindow();
        win.minimize();
        return new Promise((resolve, reject)=> {
            let child = child_process.spawn(path.join(this.app.local.path, this.app.actions[process.platform]['main']['execute']), args, {cwd: this.app.local.path});
            child.on('error', (error)=> {
                reject(error);
                win.restore()
            });
            child.on('exit', (code, signal)=> {
                // error 触发之后还可能会触发exit，但是Promise只承认首次状态转移，因此这里无需重复判断是否已经error过。
                resolve(code);
                win.restore()
            })
        })
    };
}

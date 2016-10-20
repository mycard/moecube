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
//const Promise = System._nodeRequire('bluebird');
const ini = System._nodeRequire('ini');

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
    numfont = this.get_font({'darwin': ['/System/Library/Fonts/PingFang.ttc']});
    textfont = this.get_font({'darwin': ['/System/Library/Fonts/PingFang.ttc']});

    constructor(private appsService: AppsService, private routingService: RoutingService) {
        this.refresh()
    }

    refresh() {
        this.get_decks().then((decks)=> {
            this.decks = decks;
            if (!(this.current_deck in this.decks)) {
                this.current_deck = decks[0];
            }
        })
    }

    get_font(data) {
        return new Promise((resolve, reject)=> {
            let fonts = data[process.platform]
        })
    }

    fix_fonts(ini) {
        return new Promise((resolve, reject)=>{
            this.numfont.then()
        })
    }

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

    edit_deck(deck) {
        fs.readFile(this.system_conf, {encoding: 'utf-8'}, (error, data) => {
            if (error) throw error;
            console.log(ini.parse(data));
        });
    }
}

/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from '@angular/core';
import {AppsService} from "./apps.service";
import {RoutingService} from "./routing.service";

declare var process;
declare var System;
declare var $;

const fs = System._nodeRequire('fs');
const path = System._nodeRequire('path');
const crypto = System._nodeRequire('crypto');
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


    user = {external_id: 1, username: 'zh99998'}; // for test

    room = {
        title: this.user.username + '的房间',
        rule: 0,
        mode: 1,
        start_lp: 8000,
        start_hand: 5,
        draw_count: 1,
        enable_priority: false,
        no_check_deck: false,
        no_shuffle_deck: false
    };

    rooms = [];

    constructor(private appsService: AppsService, private routingService: RoutingService) {
        this.refresh()

        // $('#game-list-modal').on('show.bs.modal', function (event) {
        //     var tbody = $('#game-list-modal tbody');
        //     for (let serfer of this.servers) {
        //
        //             if (server.private) return;
        //             var connection = new ReconnectingWebSocket(server.url);
        //             connection.onclose = function (event) {
        //                 tbody.children('[data-server-id="' + server.id + '"]').remove()
        //             };
        //             connection.onmessage = function (event) {
        //                 console.log(event)
        //                 var message = JSON.parse(event.data);
        //                 switch (message.event) {
        //                     case 'init':
        //                         tbody.children('[data-server-id="' + server.id + '"]').remove();
        //                         for (var i = 0; i < message.data.length; i++) {
        //                             tbody.append(room_template(message.data[i], server));
        //                         }
        //                         break;
        //                     case 'create':
        //                         tbody.append(room_template(message.data, server));
        //                         break;
        //                     case 'update':
        //                         $('#room-' + server.id + '-' + message.data.id).replaceWith(room_template(message.data, server));
        //                         break;
        //                     case 'delete':
        //                         $('#room-' + server.id + '-' + message.data).remove();
        //                     //auto width not works.
        //                     /*var thead = $('#game-list-modal .modal-header th');
        //                      tbody.find('tr:first-child td').each(function (index, element) {
        //                      $(thead[index]).width($(element).width())
        //                      });
        //                      */
        //                 }
        //             };
        //             roomlist_connections[server_id] = connection;
        //
        //     }
        // });
        //
        // $('#game-list-modal').on('hide.bs.modal', function (event) {
        //     for (var i in roomlist_connections) {
        //         roomlist_connections[i].close();
        //     }
        // });
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
                data['nickname'] = this.user.username;
                console.log(data)
                return data
            })
            .then(this.save_system_conf)
            .then(()=>['-j'])
            .then(this.start_game)
            .catch(reason=>alert(reason))
    };

    join_windbot(name) {
        this.join('AI#'+name, this.servers[0])
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

    create_room(options) {
        let options_buffer = new Buffer(6);
        // 建主密码 https://docs.google.com/document/d/1rvrCGIONua2KeRaYNjKBLqyG9uybs9ZI-AmzZKNftOI/edit
        options_buffer.writeUInt8((options.private ? 2 : 1) << 4, 1);
        options_buffer.writeUInt8(parseInt(options.rule) << 5 | parseInt(options.mode) << 3 | (options.enable_priority ? 1 << 2 : 0) | (options.no_check_deck ? 1 << 1 : 0) | (options.no_shuffle_deck ? 1 : 0), 2);
        options_buffer.writeUInt16LE(parseInt(options.start_lp), 3);
        options_buffer.writeUInt8(parseInt(options.start_hand) << 4 | parseInt(options.draw_count), 5);
        let checksum = 0;
        for (let i = 1; i < options_buffer.length; i++) {
            checksum -= options_buffer.readUInt8(i)
        }
        options_buffer.writeUInt8(checksum & 0xFF, 0);

        let secret = this.user.external_id % 65535 + 1;
        for (let i = 0; i < options_buffer.length; i += 2) {
            options_buffer.writeUInt16LE(options_buffer.readUInt16LE(i) ^ secret, i)
        }

        let password = options_buffer.toString('base64') + options.title.replace(/\s/, String.fromCharCode(0xFEFF));
        let room_id = crypto.createHash('md5').update(password + this.user.username).digest('base64').slice(0, 10).replace('+', '-').replace('/', '_')

        this.join(password, this.servers[0]);

        $('#game-create-modal').modal('hide');
    }



}

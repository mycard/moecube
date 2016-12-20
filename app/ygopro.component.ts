/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit, ChangeDetectorRef, Input} from "@angular/core";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";
import * as child_process from "child_process";
import {remote} from "electron";
import * as ini from "ini";
import {EncodeOptions} from "ini";
import {LoginService} from "./login.service";
import {App} from "./app";
import {Http, Headers, URLSearchParams} from "@angular/http";
import "rxjs/Rx";
import {ISubscription} from "rxjs/Subscription";
import {AppsService} from "./apps.service";

declare const $: any;

interface SystemConf {
    use_d3d: string
    antialias: string
    errorlog: string
    nickname: string
    gamename: string
    lastdeck: string
    textfont: string
    numfont: string
    serverport: string
    lastip: string
    lastport: string
    autopos: string
    randompos: string
    autochain: string
    waitchain: string
    mute_opponent: string
    mute_spectators: string
    hide_setname: string
    hide_hint_button: string
    control_mode: string
    draw_field_spell: string
    separate_clear_button: string
    roompass: string
}

interface Server {
    id?: string
    url?: string
    address: string
    port: number
}

interface Room {
    id?: string
    title?: string
    server?: Server
    private?: boolean
    options: Options;
}

interface Options {
    mode: number,
    rule: number,
    start_lp: number,
    start_hand: number,
    draw_count: number,
    enable_priority: boolean,
    no_check_deck: boolean,
    no_shuffle_deck: boolean
    lflist?: number;
    time_limit?: number
}
interface Points {
    exp: number,
    exp_rank: number,
    pt: number,
    arena_rank: number,
    win: number,
    lose: number,
    draw: number,
    all: number,
    ratio: number
}


let matching: ISubscription | undefined;
let matching_arena: string | undefined;

@Component({
    moduleId: module.id,
    selector: 'ygopro',
    templateUrl: 'ygopro.component.html',
    styleUrls: ['ygopro.component.css'],
})
export class YGOProComponent implements OnInit {
    @Input()
    app: App;
    decks: string[] = [];
    current_deck: string;
    system_conf: string;
    numfont: string[];
    textfont: string[];
    points: Points;

    windbot = ["琪露诺", "谜之剑士LV4", "复制植物", "尼亚"];

    servers: Server[] = [{
        id: 'tiramisu',
        url: 'wss://tiramisu.mycard.moe:7923',
        address: "112.124.105.11",
        port: 7911
    }];


    default_options: Options = {
        mode: 1,
        rule: 0,
        start_lp: 8000,
        start_hand: 5,
        draw_count: 1,
        enable_priority: false,
        no_check_deck: false,
        no_shuffle_deck: false,
        lflist: 0,
        time_limit: 180
    };

    room: Room = {title: this.loginService.user.username + '的房间', options: Object.assign({}, this.default_options)};

    rooms: Room[] = [];

    connections: WebSocket[] = [];

    matching: ISubscription | undefined;
    matching_arena: string | undefined;

    constructor(private http: Http, private appsService: AppsService, private loginService: LoginService, private ref: ChangeDetectorRef) {
        switch (process.platform) {
            case 'darwin':
                this.numfont = ['/System/Library/Fonts/SFNSTextCondensed-Bold.otf'];
                this.textfont = ['/System/Library/Fonts/PingFang.ttc'];
                break;
            case 'win32':
                this.numfont = [path.join(process.env['SystemRoot'], 'Fonts', 'arialbd.ttf')];
                this.textfont = [path.join(process.env['SystemRoot'], 'Fonts', 'msyh.ttc'), path.join(process.env['SystemRoot'], 'Fonts', 'msyh.ttf'), path.join(process.env['SystemRoot'], 'Fonts', 'simsun.ttc')];
                break;
        }

        this.matching = matching;
        this.matching_arena = matching_arena;
    }

    async ngOnInit() {
        this.system_conf = path.join(this.app.local!.path, 'system.conf');
        await this.refresh();

        let modal = $('#game-list-modal');

        modal.on('show.bs.modal', () => {
            this.connections = this.servers.map((server) => {
                let connection = new WebSocket(server.url!);
                connection.onclose = () => {
                    this.rooms = this.rooms.filter(room => room.server != server)
                };
                connection.onmessage = (event) => {
                    let message = JSON.parse(event.data);
                    //console.log(message)
                    switch (message.event) {
                        case 'init':
                            this.rooms = this.rooms.filter(room => room.server != server).concat(message.data.map((room: Room) => Object.assign({server: server}, room)));
                            break;
                        case 'create':
                            this.rooms.push(Object.assign({server: server}, message.data));
                            break;
                        case 'update':
                            Object.assign(this.rooms.find(room => room.server == server && room.id == message.data.id), message.data);
                            break;
                        case 'delete':
                            this.rooms.splice(this.rooms.findIndex(room => room.server == server && room.id == message.data), 1);
                    }
                    this.ref.detectChanges()
                };
                return connection;
            });
        });

        modal.on('shown.bs.modal', () => {
            $('td.users').tooltip({
                selector: '[data-toggle=tooltip]'
            });
        });

        modal.on('hide.bs.modal', () => {
            for (let connection of this.connections) {
                connection.close();
            }
            this.connections = []
        });
    }

    async refresh() {
        let decks = await this.get_decks();
        this.decks = decks;
        if (!(this.decks.includes(this.current_deck))) {
            this.current_deck = decks[0];
        }
        // https://mycard.moe/ygopro/api/user?username=ozxdno
        let params = new URLSearchParams();
        params.set('username', this.loginService.user.username);
        try {
            this.points = await this.http.get('https://mycard.moe/ygopro/api/user', {search: params}).map((response) => response.json()).toPromise()
        } catch (error) {
            console.log(error)
        }
    };

    get_decks(): Promise<string[]> {
        return new Promise((resolve, reject) => {
            fs.readdir(path.join(this.app.local!.path, 'deck'), (error, files) => {
                if (error) {
                    resolve([])
                } else {
                    resolve(files.filter(file => path.extname(file) == ".ydk").map(file => path.basename(file, '.ydk')));
                }
            })
        })
    }

    async get_font(files: string[]): Promise<string | undefined> {
        for (let file of files) {
            let found = await new Promise((resolve) => fs.access(file, fs.constants.R_OK, error => resolve(!error)));
            if (found) {
                return file;
            }
        }
    }

    async delete_deck(deck: string) {
        await new Promise(resolve => fs.unlink(path.join(this.app.local!.path, 'deck', deck + '.ydk'), resolve));
        return this.refresh()
    }

    async fix_fonts(data: SystemConf) {
        if (!await this.get_font([data.numfont])) {
            let font = await this.get_font(this.numfont);
            if (font) {
                data['numfont'] = font
            }
        }

        if (data.textfont == 'c:/windows/fonts/simsun.ttc 14' || !await this.get_font([data.textfont.split(' ', 2)[0]])) {
            let font = await this.get_font(this.textfont);
            if (font) {
                data['textfont'] = `${font} 14`
            }
        }
    };

    load_system_conf(): Promise<SystemConf> {
        return new Promise((resolve, reject) => {
            fs.readFile(this.system_conf, {encoding: 'utf-8'}, (error, data) => {
                if (error) return reject(error);
                resolve(ini.parse(data));
            });
        })
    };

    save_system_conf(data: SystemConf) {
        return new Promise((resolve, reject) => {
            fs.writeFile(this.system_conf, ini.unsafe(ini.stringify(data, <EncodeOptions>{whitespace: true})), (error) => {
                if (error) return reject(error);
                resolve(data);
            });
        })
    };

    async join(name: string, server: Server) {
        let system_conf = await this.load_system_conf();
        await this.fix_fonts(system_conf);
        system_conf.lastdeck = this.current_deck;
        system_conf.lastip = server.address;
        system_conf.lastport = server.port.toString();
        system_conf.roompass = name;
        system_conf.nickname = this.loginService.user.username;
        await this.save_system_conf(system_conf);
        return this.start_game(['-j']);
    };

    async edit_deck(deck: string) {
        let system_conf = await this.load_system_conf();
        await this.fix_fonts(system_conf);
        system_conf.lastdeck = deck;
        await this.save_system_conf(system_conf);
        return this.start_game(['-d']);
    }

    join_windbot(name: string) {
        return this.join('AI#' + name, this.servers[0])
    }

    async start_game(args: string[]) {
        let win = remote.getCurrentWindow();
        win.minimize();
        return new Promise((resolve, reject) => {
            let child = child_process.spawn(path.join(this.app.local!.path, this.app.actions.get('main')!.execute), args, {
                cwd: this.app.local!.path,
                stdio: 'inherit'
            });
            child.on('error', (error) => {
                reject(error);
                win.restore()
            });
            child.on('exit', async(code, signal) => {
                // error 触发之后还可能会触发exit，但是Promise只承认首次状态转移，因此这里无需重复判断是否已经error过。
                await this.refresh();
                resolve();
                win.restore()
            })
        })
    };

    create_room(room: Room) {
        let options_buffer = new Buffer(6);
        // 建主密码 https://docs.google.com/document/d/1rvrCGIONua2KeRaYNjKBLqyG9uybs9ZI-AmzZKNftOI/edit
        options_buffer.writeUInt8((room.private ? 2 : 1) << 4, 1);
        options_buffer.writeUInt8(room.options.rule << 5 | room.options.mode << 3 | (room.options.enable_priority ? 1 << 2 : 0) | (room.options.no_check_deck ? 1 << 1 : 0) | (room.options.no_shuffle_deck ? 1 : 0), 2);
        options_buffer.writeUInt16LE(room.options.start_lp, 3);
        options_buffer.writeUInt8(room.options.start_hand << 4 | room.options.draw_count, 5);
        let checksum = 0;
        for (let i = 1; i < options_buffer.length; i++) {
            checksum -= options_buffer.readUInt8(i)
        }
        options_buffer.writeUInt8(checksum & 0xFF, 0);

        let secret = this.loginService.user.external_id % 65535 + 1;
        for (let i = 0; i < options_buffer.length; i += 2) {
            options_buffer.writeUInt16LE(options_buffer.readUInt16LE(i) ^ secret, i)
        }

        let password = options_buffer.toString('base64') + (room.title!).replace(/\s/, String.fromCharCode(0xFEFF));
        let room_id = crypto.createHash('md5').update(password + this.loginService.user.username).digest('base64').slice(0, 10).replace('+', '-').replace('/', '_');

        this.join(password, this.servers[0]);
    }

    join_room(room: Room) {
        let options_buffer = new Buffer(6);
        options_buffer.writeUInt8(3 << 4, 1);
        let checksum = 0;
        for (let i = 1; i < options_buffer.length; i++) {
            checksum -= options_buffer.readUInt8(i)
        }
        options_buffer.writeUInt8(checksum & 0xFF, 0);

        let secret = this.loginService.user.external_id % 65535 + 1;
        for (let i = 0; i < options_buffer.length; i += 2) {
            options_buffer.writeUInt16LE(options_buffer.readUInt16LE(i) ^ secret, i)
        }


        let password = options_buffer.toString('base64') + room.id;

        this.join(password, room.server!);
    }

    request_match(arena = 'entertain') {
        let headers = new Headers();
        headers.append("Authorization", "Basic " + new Buffer(this.loginService.user.username + ":" + this.loginService.user.external_id).toString('base64'));
        let search = new URLSearchParams();
        search.set("arena", arena);
        this.matching_arena = matching_arena = arena;
        this.matching = matching = this.http.post('https://api.mycard.moe/ygopro/match', null, {
            headers: headers,
            search: search
        }).map(response => response.json())
            .subscribe((data) => {
                this.join(data['password'], {
                    address: data['address'],
                    port: data['port']
                });
            }, (error) => {
                alert(`匹配失败\n${error}`)
            }, () => {
                this.matching = matching = undefined;
                this.matching_arena = matching_arena = undefined;
                this.ref.detectChanges()
            });
    }

    cancel_match() {
        this.matching!.unsubscribe();
        this.matching = matching = undefined;
        this.matching_arena = matching_arena = undefined;
    }
}

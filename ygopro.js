"use strict";
/**
 * Created by zh99998 on 16/1/24.
 */
const child_process = require('child_process');
const http = require('http');
const querystring = require('querystring');
const url = require('url');
const fs = require('fs');
const path = require('path');

const electron = require('electron');
const BrowserWindow = electron.BrowserWindow;

const ygopro_directory = 'ygopro';
const ygopro_main = 'ygopro.app/Contents/MacOS/ygopro';
const ygopro_system_conf = path.join(ygopro_directory, 'system.conf');
const ygopro_decks = path.join(ygopro_directory, 'deck');

const EventEmitter = require('events');
const ygopro = new EventEmitter();

ygopro.on('start', function (system, args) {
    fs.readFile(ygopro_system_conf, 'utf8', (error, conf)=> {
        if (error) return console.log(error);
        let options = {};
        for (let line of conf.split("\n")) {
            if (line.charAt(0) == '#') continue;
            if (!line[1])continue;
            line = line.split(' = ');
            options[line[0]] = line[1];
        }
        Object.assign(options, system);

        let result = [];
        for (let key in options) {
            result.push(key + " = " + options[key])
        }

        fs.writeFile(ygopro_system_conf, result.join("\n"), (error)=> {
            if (error) return console.log(error);
            if (args) {
                for (let window of BrowserWindow.getAllWindows()) {
                    window.minimize()
                }
                let child = child_process.spawn(ygopro_main, [args], {cwd: ygopro_directory});
                child.on('exit', ()=> {
                    for (let window of BrowserWindow.getAllWindows()) {
                        window.restore()
                    }
                })
            }
        })
    });
});

ygopro.on('delete', function (file) {
    if (path.dirname(file) == 'deck' && path.extname(file) == '.ydk') {
        fs.unlink(path.join(ygopro_directory, file));
        let deck = path.basename(file, '.ydk');
        for (let i in decks) {
            if (decks[i].name === deck) decks.splice(i, 1);
        }
    } // reject others
});

module.exports = ygopro;

const system = {};
const decks = [];

let pending = 2;

fs.readFile(ygopro_system_conf, 'utf8', (error, file)=> {
    if (error) return done();
    for (let line of file.split("\n")) {
        if (line.charAt(0) == '#') continue;
        line = line.split(' = ');
        if (!line[1])continue;
        system[line[0]] = line[1];
    }
    done()
});

fs.readdir(ygopro_decks, (error, files)=> {
    if (error) return done();
    let deckfiles = [];
    for (let filename of files) {
        if (path.extname(filename) == '.ydk') {
            deckfiles.push(filename);
        }
    }
    for (let filename of deckfiles) {
        let deck = {name: path.basename(filename, '.ydk'), cards: []};
        pending++;
        fs.stat(path.join(ygopro_decks, filename), (error, stats)=> {
            if (error)return done();
            deck.created_at = stats.birthtime;
            deck.updated_at = stats.mtime;
            fs.readFile(path.join(ygopro_decks, filename), 'utf8', (error, file)=> {
                if (error)return done();
                let side = false;
                let cards = {};
                for (let line of file.split("\n")) {
                    if (line.charAt(0) == '#') continue;
                    if (line.slice(0, 5) == '!side') {
                        for (let card_id in cards) {
                            deck.cards.push(cards[card_id]);
                        }
                        cards = {};
                    }
                    let id = parseInt(line);
                    if (!id)continue;
                    if (cards[id]) {
                        cards[id].count++;
                    } else {
                        cards[id] = {id: id, count: 1, side: side};
                    }
                }
                for (let card_id in cards) {
                    deck.cards.push(cards[card_id]);
                }
                decks.push(deck);
                done()
            })
        })
    }
    done()
});

function done() {
    pending--;
    if (pending == 0) {
        start_server();
    }
}

function start_server() {
    const WebSocketServer = require('ws').Server;
    const server = new WebSocketServer({host: '127.0.0.1', port: 9999});

    server.on('connection', (connection) => {
        connection.send(JSON.stringify({
            event: 'init',
            data: {
                system: system,
                decks: decks
            }
        }));
        connection.on('message', (message) => {
            message = JSON.parse(message);
            ygopro.emit(message.event, ...message.data);
        });
    });
}

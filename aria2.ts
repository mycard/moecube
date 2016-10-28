/**
 * Created by weijian on 2016/10/27.
 */
const Rx = require("rxjs/Rx");
const {ipcMain}= require('electron');
import {ChildProcess, spawn} from "child_process";
// import * as Aria2 from "aria2";
const Aria2 = require("aria2");

let a = (createProcess("D:/Github/mycard/bin/aria2c.exe", ['--enable-rpc', '--rpc-allow-origin-all', "--continue", "--split=10", "--min-split-size=1M", "--max-connection-per-server=10"]))
a.on('error', (error)=> {
    console.log(error);
});
// console.log(Aria2,2);
function createProcess(aria2c_path: string, args: string[] = []): ChildProcess {
    return spawn(aria2c_path, args);
}

let options = {'host': 'localhost', 'port': 6800, 'secure': false}
let aria2 = new Aria2(options);

aria2.onDownloadComplete = (response)=> {
    console.log(response);
};

let open = aria2.open();
function addUri(uri: string[], path: string) {
    return open.then(()=> {
        return aria2.addUri(uri, {'dir': path});
    });
}
function pause(gid: string): Promise<string> {
    return aria2.pause(gid)
}

function reportStatus() {
    aria2.tellActive()
}

//ipcMain.on()

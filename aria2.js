"use strict";
/**
 * Created by weijian on 2016/10/27.
 */
var Rx = require("rxjs/Rx");
var ipcMain = require('electron').ipcMain;
var child_process_1 = require("child_process");
// import * as Aria2 from "aria2";
var Aria2 = require("aria2");
var a = (createProcess("D:/Github/mycard/bin/aria2c.exe", ['--enable-rpc', '--rpc-allow-origin-all', "--continue", "--split=10", "--min-split-size=1M", "--max-connection-per-server=10"]));
a.on('error', function (error) {
    console.log(error);
});
// console.log(Aria2,2);
function createProcess(aria2c_path, args) {
    if (args === void 0) { args = []; }
    return child_process_1.spawn(aria2c_path, args);
}
var options = { 'host': 'localhost', 'port': 6800, 'secure': false };
var aria2 = new Aria2(options);
aria2.onDownloadComplete = function (response) {
    console.log(response);
};
var open = aria2.open();
function addUri(uri, path) {
    return open.then(function () {
        return aria2.addUri(uri, { 'dir': path });
    });
}
function pause(gid) {
    return aria2.pause(gid);
}
function reportStatus() {
    aria2.tellActive();
}
//ipcMain.on()
//# sourceMappingURL=aria2.js.map
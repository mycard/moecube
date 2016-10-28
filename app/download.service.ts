/**
 * Created by weijian on 2016/10/26.
 */

import {Injectable} from "@angular/core";
import {SettingsService} from "./settings.sevices";
import {ipcRenderer} from "electron";

@Injectable()
export class DownloadService {

    constructor(private settingsService: SettingsService) {
        ipcRenderer.send("download-message", "123");
    }

    sendEvent(event, args) {
        ipcRenderer.send()
    }

    listenEvent() {
        console.log(ipcRenderer);
    }


}

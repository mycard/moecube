import {Component, Renderer, ChangeDetectorRef, OnInit} from "@angular/core";
import {remote} from "electron";
import {LoginService} from "./login.service";
const autoUpdater: Electron.AutoUpdater = remote.getGlobal('autoUpdater');


@Component({
    moduleId: module.id,
    selector: 'mycard',
    templateUrl: 'mycard.component.html',
    styleUrls: ['mycard.component.css'],

})

export class MyCardComponent implements OnInit {
    currentPage: string = "lobby";

    platform = process.platform;
    currentWindow = remote.getCurrentWindow();
    window = window;

    ngOnInit() {

    }

    constructor(private renderer: Renderer, private loginService: LoginService, private ref: ChangeDetectorRef) {
        // renderer.listenGlobal('window', 'message', (event) => {
        //     console.log(event);
        //     // Do something with 'event'
        // });

        this.currentWindow.on('maximize', () => ref.detectChanges());
        this.currentWindow.on('unmaximize', () => ref.detectChanges());

        autoUpdater.on('error', (error) => {
            console.log('autoUpdater', 'error', error.message)
        });
        autoUpdater.on('checking-for-update', () => {
            console.log('autoUpdater', 'checking-for-update')
        });
        autoUpdater.on('update-available', () => {
            console.log('autoUpdater', 'update-available')
        });
        autoUpdater.on('update-not-available', () => {
            console.log('autoUpdater', 'update-not-available')
        });
        autoUpdater.on('update-downloaded', (event) => {
            console.log('autoUpdater', 'update-downloaded')
        });
    }
}

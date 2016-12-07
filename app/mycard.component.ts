import {Component, Renderer, ChangeDetectorRef, OnInit, ElementRef, ViewChild} from "@angular/core";
import {remote} from "electron";
import {LoginService} from "./login.service";
const autoUpdater: Electron.AutoUpdater = remote.getGlobal('autoUpdater');
declare const $: any;

@Component({
    moduleId: module.id,
    selector: 'mycard',
    templateUrl: 'mycard.component.html',
    styleUrls: ['mycard.component.css'],

})
export class MyCardComponent implements OnInit {
    currentPage: string = "lobby";

    update_status: string | undefined = remote.getGlobal('update_status');
    update_error: string | undefined;
    currentWindow = remote.getCurrentWindow();
    window = window;

    @ViewChild('error')
    error: ElementRef;
    @ViewChild('checking_for_update')
    checking_for_update: ElementRef;
    @ViewChild('update_available')
    update_available: ElementRef;
    @ViewChild('update_downloaded')
    update_downloaded: ElementRef;
    update_elements: Map<string, ElementRef>;

    ngOnInit() {
        this.update_elements = new Map(Object.entries({
            'error': this.error,
            'checking-for-update': this.checking_for_update,
            'update-available': this.update_available,
            'update-downloaded': this.update_downloaded
        }));
    }

    constructor(private renderer: Renderer, private loginService: LoginService, private ref: ChangeDetectorRef) {
        // renderer.listenGlobal('window', 'message', (event) => {
        //     console.log(event);
        //     // Do something with 'event'
        // });

        this.currentWindow.on('maximize', () => this.ref.detectChanges());
        this.currentWindow.on('unmaximize', () => this.ref.detectChanges());

        autoUpdater.on('error', (error) => {
            this.set_update_status('error');
        });
        autoUpdater.on('checking-for-update', () => {
            this.set_update_status('checking-for-update');
        });
        autoUpdater.on('update-available', () => {
            this.set_update_status('update-available');
        });
        autoUpdater.on('update-not-available', () => {
            this.set_update_status('update-not-available');
        });
        autoUpdater.on('update-downloaded', (event) => {
            this.set_update_status('update-downloaded');
        });

    }

    update_retry() {
        autoUpdater.checkForUpdates()
    }

    update_install() {
        autoUpdater.quitAndInstall()
    }

    set_update_status(status: string) {
        console.log('autoUpdater', status);
        if (this.update_status) {
            let element = this.update_elements.get(this.update_status);
            if (element) {
                $(element.nativeElement).tooltip('dispose')
            }
        }
        this.update_status = status;
        this.ref.detectChanges();

        let element = this.update_elements.get(this.update_status);
        if (element) {
            $(element.nativeElement).tooltip({placement: 'bottom', container: 'body'})
        }
    }
}

import {Component, Renderer} from "@angular/core";
import {TranslateService} from "ng2-translate";
import {LoginService} from "./login.service";
const electron = System._nodeRequire('electron');
declare var process;
declare var System;


@Component({
    selector: 'mycard',
    templateUrl: 'app/mycard.component.html',
    styleUrls: ['app/mycard.component.css'],

})

export class MyCardComponent {
    currentPage: string = "lobby";

    platform = process.platform;

    constructor(private renderer: Renderer, private translate: TranslateService, private loginService: LoginService) {
        renderer.listenGlobal('window', 'message', (event) => {
            console.log(event);
            // Do something with 'event'
        });

        // this language will be used as a fallback when a translation isn't found in the current language
        translate.setDefaultLang('en-US');

        // the lang to use, if the lang isn't available, it will use the current loader to get them
        translate.use(electron.remote.app.getLocale());

    }


    refresh() {
        electron.remote.getCurrentWindow().reload()
    }
}

import {Component, Renderer} from "@angular/core";
import {TranslateService} from "ng2-translate";
import {remote} from "electron";
import {LoginService} from "./login.service";


@Component({
    selector: 'mycard',
    templateUrl: 'app/mycard.component.html',
    styleUrls: ['app/mycard.component.css'],

})

export class MyCardComponent {
    currentPage: string = "lobby";

    platform = process.platform;
    currentWindow = remote.getCurrentWindow();
    window = window;

    constructor(private renderer: Renderer, private translate: TranslateService, private loginService: LoginService) {
        renderer.listenGlobal('window', 'message', (event) => {
            console.log(event);
            // Do something with 'event'
        });

        // this language will be used as a fallback when a translation isn't found in the current language
        translate.setDefaultLang('en-US');

        // the lang to use, if the lang isn't available, it will use the current loader to get them
        translate.use(remote.app.getLocale());

    }

}

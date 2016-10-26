/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService} from "./login.service";
@Component({
    selector: 'lobby',
    templateUrl: 'app/lobby.component.html',
    styleUrls: ['app/lobby.component.css'],
})
export class LobbyComponent {
    candy_url;

    constructor(private appsService: AppsService, private loginService: LoginService) {
        this.candy_url = './candy/index.html?jid=' + this.loginService.user.username + '@mycard.moe&password=' + this.loginService.user.external_id + '&nickname=' + this.loginService.user.username + '&autojoin=ygopro_china_north@conference.mycard.moe'
    }
}

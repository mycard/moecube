/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from "@angular/core";
import {RoutingService} from "./routing.service";
import {AppsService} from "./apps.service";
@Component({
    selector: 'lobby',
    templateUrl: 'app/lobby.component.html',
    styleUrls: ['app/lobby.component.css'],
})
export class LobbyComponent {
    constructor(private routingService: RoutingService, private appsService: AppsService) {
    }
}

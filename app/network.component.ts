import { ChangeDetectorRef, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, Injectable } from '@angular/core';
import { AppsService } from './apps.service';
import {App} from './app';

@Component({
    moduleId: module.id,
    selector: 'network',
    templateUrl: 'network.component.html',
    styleUrls: ['network.component.css'],
})
@Injectable()
export class NetworkComponent {
    @Input()
    currentApp: App;

    constructor(private appsService: AppsService) {
        console.log( 'constructor' );
    }
}

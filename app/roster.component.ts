/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, Input, EventEmitter, Output, OnInit, OnChanges} from '@angular/core';
@Component({
    moduleId: module.id,
    selector: 'roster',
    templateUrl: 'roster.component.html',
    styleUrls: ['roster.component.css'],
})
export class RosterComponent implements OnInit, OnChanges {
    @Input()
    roster: any;
    @Output()
    chat = new EventEmitter<string>();

    ngOnInit() {
        // console.log(this.roster);
    }

    ngOnChanges() {
        // console.log(this.roster);
    }
}

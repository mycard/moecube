/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, EventEmitter, Input, OnChanges, OnInit, Output } from '@angular/core';
@Component({

  selector: 'roster',
  templateUrl: './roster.component.html',
  styleUrls: ['./roster.component.css'],
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

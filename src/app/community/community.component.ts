import {Component, OnInit} from '@angular/core';
import {shell} from 'electron';

@Component({
  selector: 'mycard-community',
  templateUrl: './community.component.html',
  styleUrls: ['./community.component.css']
})
export class CommunityComponent implements OnInit {

  shell = shell;

  constructor() {
  }

  ngOnInit() {
  }

}

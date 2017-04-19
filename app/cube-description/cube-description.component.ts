/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input, OnInit } from '@angular/core';
import { remote } from 'electron';
import { Cube } from '../cube';


@Component({
  selector: 'cube-description',
  templateUrl: './cube-description.component.html',
  styleUrls: ['./cube-description.component.css'],
})
export class CubeDescriptionComponent {

  @Input()
  currentCube: Cube;
}

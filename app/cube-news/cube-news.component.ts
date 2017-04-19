/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input } from '@angular/core';
import { Cube } from '../cube';


@Component({
  selector: 'cube-news',
  templateUrl: './cube-news.component.html',
  styleUrls: ['./cube-news.component.css'],
})
export class CubeNewsComponent {
  @Input()
  currentCube: Cube;
}

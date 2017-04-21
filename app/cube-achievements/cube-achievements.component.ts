/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input } from '@angular/core';
import { Cube } from '../cube';


@Component({
  selector: 'cube-achievements',
  templateUrl: './cube-achievements.component.html',
  styleUrls: ['./cube-achievements.component.css'],
})
export class CubeAchievementsComponent {
  @Input()
  currentCube: Cube;
}

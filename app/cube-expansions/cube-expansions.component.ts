/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { Cube } from '../cube';
import { CubesService } from '../cubes.service';


@Component({
  selector: 'cube-expansions',
  templateUrl: './cube-expansions.component.html',
  styleUrls: ['./cube-expansions.component.css'],
})
export class CubeExpansionsComponent implements OnChanges {

  @Input()
  currentCube: Cube;
  mods: Cube[];

  constructor(public cubesService: CubesService) {
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.currentCube) {
      if (this.currentCube.isReady()) {
        this.mods = this.cubesService.findChildren(this.currentCube);
      } else {
        this.mods = [];
      }
    }
  }
}

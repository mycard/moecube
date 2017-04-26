/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { Achievement, Cube } from '../cube';


@Component({
  selector: 'cube-achievements',
  templateUrl: './cube-achievements.component.html',
  styleUrls: ['./cube-achievements.component.css'],
})
export class CubeAchievementsComponent implements OnChanges {
  @Input()
  currentCube: Cube;

  acLocks: any[] = [];
  acUnlocks: any[] = [];

  Titles: string[] = [];
  progressTotal: string[] = [];


  ngOnChanges(changes: SimpleChanges): void {
    if (changes.currentCube) {

      this.acLocks = [];
      this.acUnlocks = [];
      console.log(this.currentCube);
      console.log(Cube);
      for (let ac of this.currentCube.achievements) {
        let title = ac.name + '\n' + ac.description + '\n' + (ac.progress_max ? ac.progress_value + '' +
            '/' + ac.progress_max + ' ' + ((ac.progress_value / ac.progress_max * 100).toFixed(2)).replace(/0+$/, '') + '%' : '');
        if (ac.unlocked) {
          this.acUnlocks.push(ac);
          this.Titles.push(title + '1/1 100%');
        } else {
          this.acLocks.push(ac);
          this.Titles.push(title + '0/1 0%');
        }
      }
      let acLocksL = this.acLocks.length;
      let acUnlocksL = this.acUnlocks.length;
      this.progressTotal[0] = acUnlocksL + '/' + (acLocksL + acUnlocksL);
      this.progressTotal[1] = ((acUnlocksL / (acLocksL + acUnlocksL) * 100).toFixed(2)).replace(/(0+|.00)$/, '') + '%';
    }
  }


  getTitle(ac: Achievement): String {
    let title = ac.name + '\n' + ac.description + '\n' + (ac.progress_max ? ac.progress_value + '' +
        '/' + ac.progress_max + ' ' + ((ac.progress_value / ac.progress_max * 100).toFixed(2)).replace(/(0+|.00)$/, '') + '%' : '');
    if (ac.unlocked) {
      return title + (ac.progress_max ? '' : '1/1 ') + ac.unlocked_at.toLocaleDateString();
    } else {
      return title + (ac.progress_max ? '' : '0/1 0%');
    }
  }

}

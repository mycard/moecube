/**
 * Created by zh99998 on 16/9/2.
 */
import {ChangeDetectorRef, Component, Input, Pipe} from '@angular/core';
import {Cube} from '../cube';


@Component({
  selector: 'cube-description',
  templateUrl: './cube-description.component.html',
  styleUrls: ['./cube-description.component.css'],
})

@Pipe({name: 'keys'})

export class CubeDescriptionComponent {

  @Input()
  currentCube: Cube;

  divOpacity: number[] = [1, 0, 0];
  div1 = 1;
  div2 = 0;
  color1 = 'red';
  hrefs = 'http://abc.efg.ijk';
  imgsrc: string[] = [
    'http://cdn.akamai.steamstatic.com/steam/apps/545980/ss_bfc8d95b53734e03998342b1def248f560c440e3.600x338.jpg?t=1492488208',
    'http://cdn.akamai.steamstatic.com/steam/apps/15370/0000004764.1920x1080.jpg?t=1447351397',
    'http://cdn.akamai.steamstatic.com/steam/apps/15370/0000004767.600x338.jpg?t=1447351397'
  ];

  constructor(private ref: ChangeDetectorRef) {

  }

  transform(value, args: string[]): any {
    let keys = [];
    for (let key in value) {
      keys.push({key: key, value: value[key]});
    }
    return keys;
  }

  test(v: number): void {
    console.log(v);
    console.log(this.divOpacity[1])
  }

  show(num1: number): void {
    console.log(num1);
    let divOpacity = this.divOpacity;
    divOpacity.map(function (val, key) {
      divOpacity[key] = 0;
    })
    divOpacity[num1] = 1;
    console.log(this.divOpacity);
  }

  showxx(num: number): void {
    console.log(num);
    this.div1 = 0;
    this.div2 = 1;
  }

  changecolor() {
    this.color1 = 'green';
    console.log(this.color1);
    this.ref.detectChanges()
  }

  ngStyle() {
    let styles = {
      'background': this.color1
    }
    return styles;
  }
}

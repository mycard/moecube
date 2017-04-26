/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { Cube } from '../cube';
import Timer = NodeJS.Timer;


@Component({
  selector: 'cube-description',
  templateUrl: './cube-description.component.html',
  styleUrls: ['./cube-description.component.css'],
})

export class CubeDescriptionComponent implements OnChanges {

  @Input()
  currentCube: Cube;

  videosrc: any[];
  videosrc_now: string;
  imgsrc: string[];
  divOpacity: number[];
  selectId = 0;
  timeOutId: Timer;
  carouselLock = false;
  carouselTime = 5000;

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.currentCube) {
      clearTimeout(this.timeOutId);
      this.videosrc = [];
      this.imgsrc = [];
      this.divOpacity = [];
      this.selectId = 0;

      for (let val of this.currentCube.trailer) {
        if (val.type === 'video') {
          this.videosrc.push([val.url, val.url2]);
        } else if (val.type === 'image') {
          this.imgsrc.push(val.url);
        }
        if (this.divOpacity.length) {
          this.divOpacity.push(0);
        } else {
          this.divOpacity.push(1);
        }
      }
      this.videosrc_now = this.videosrc[0] ? this.videosrc[0][0] : '';
    }
  }

  nextvedio(key: number): void {
    console.log('nextvedio');
    let videosrc = this.videosrc;
    if (key + 1 < videosrc.length) {
      this.videosrc_now = videosrc[key + 1][0];
      this.appear(key + 1);
      console.log(videosrc);
    } else {
      this.nextpic(key);
    }
  }

  nextpic(key: number): void {
    let that = this;
    console.log('nextpic' + key);
    if (this.carouselLock) {
      this.timeOutId = setTimeout(function () {
        that.nextpic(key);
      }, this.carouselTime);
    } else {
      key = this.divOpacity.length > key + 1 ? key : this.videosrc.length - 1;
      this.appear(key + 1);
      this.timeOutId = setTimeout(function () {
        that.nextpic(key + 1);
      }, this.carouselTime);
    }
  }

  appear(key: number): void {
    console.log('appear' + key);
    let divOpacity = this.divOpacity;
    this.selectId = key;
    divOpacity.map(function (val, key2) {
      divOpacity[key2] = 0;
    });
    divOpacity[key] = 1;
  }

  select(key: number): void {
    clearTimeout(this.timeOutId);
    let videosrc = this.videosrc;
    let videos = <NodeListOf<HTMLVideoElement>>document.getElementsByName('video');
    videos[0].pause();
    if (key < videosrc.length) {
      this.videosrc_now = videosrc[key][0];
      console.log(videosrc);
      console.log(this.videosrc_now);
      videos[0].play();
      this.appear(key);
    } else {
      this.nextpic(key - 1);
    }
  }

  carouselUnlock(): void {
    this.carouselLock = false;
  }

  carouselLock_f(): void {
    this.carouselLock = true;
  }
}

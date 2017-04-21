/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, Input, OnChanges, SimpleChanges} from '@angular/core';
import {Cube} from '../cube';


@Component({
  selector: 'cube-description',
  templateUrl: './cube-description.component.html',
  styleUrls: ['./cube-description.component.css'],
})

export class CubeDescriptionComponent implements OnChanges {


  @Input()
  currentCube: Cube;

  // videosrc: any[] = [
  //   ['file:///C:/Users/break/Desktop/movie480.webm', 'file:///C:/Users/break/Desktop/movie.png'],
  //   ['file:///C:/Users/break/Desktop/movie480_2.webm', 'file:///C:/Users/break/Desktop/movie_2.jpg']
  // ];
  // imgsrc: string[] = [
  //   'http://cdn.akamai.steamstatic.com/steam/apps/545980/ss_bfc8d95b53734e03998342b1def248f560c440e3.600x338.jpg?t=1492488208',
  //   'http://cdn.akamai.steamstatic.com/steam/apps/15370/0000004764.1920x1080.jpg?t=1447351397',
  //   'http://cdn.akamai.steamstatic.com/steam/apps/15370/0000004767.600x338.jpg?t=1447351397'
  // ];
  //
  // divOpacity: number[] = (function (imgsrc, videosrc) {
  //   length = imgsrc.length + videosrc.length;
  //   let arr = [1];
  //   while (--length > 0) {
  //     arr.push(0)
  //   }
  //   return arr;
  // })(this.imgsrc, this.videosrc)
  videosrc: any[];
  videosrc_now: string;
  imgsrc: string[];
  divOpacity: number[];
  selectId = 0;
  timeOutId: number;

  ngOnChanges(changes: SimpleChanges): void {
    if (changes.currentCube) {

      let trailer = this.currentCube.trailer;
      let videosrc = this.videosrc = [];
      this.videosrc_now="";
      let imgsrc = this.imgs rc = [];
      let divOpacity = this.divOpacity = [];
      this.selectId = 0;

      for (let val of trailer) {
        if (val.type === 'video') {
          videosrc.push([val.url, val.url2]);
        } else if (val.type === 'image') {
          imgsrc.push(val.url);
        }
        if (divOpacity.length) {
          divOpacity.push(0);
        } else {
          divOpacity.push(1);
        }
      }
    }
  }

  nextvedio(key): void {
    console.log('nextvedio');
    let videos = document.getElementsByName('video');
    if (key + 1 < videos.length) {
      videos[key + 1].play();
      this.appear(key + 1);
    } else {
      this.nextpic(key);
    }
  }

  nextpic(key): void {
    console.log('nextpic' + key);
    let that = this;
    key = this.divOpacity.length > key + 1 ? key : this.videosrc.length - 1;
    this.appear(key + 1);
    this.timeOutId = setTimeout(function () {
      that.nextpic(key + 1)
    }, 1000);
  }

  test(v: number): void {
    console.log(this.currentCube);
    console.log(this.divOpacity);
    console.log(v);
    console.log(this.divOpacity[1])
  }

  appear(key: number): void {
    console.log('appear' + key)
    let divOpacity = this.divOpacity;
    this.selectId = key;
    divOpacity.map(function (val, key2) {
      divOpacity[key2] = 0;
    })
    divOpacity[key] = 1;
  }

  select(key: number): void {
    console.log(this.currentCube);
    clearTimeout(this.timeOutId);
    this.stop();

    let videos = document.getElementsByName('video');
    if (key < videos.length) {
      videos[key].play();
      this.appear(key);
    } else {
      this.nextpic(key - 1);
    }

    // this.appear(key);

  }

  play(key, ele) {
    console.log('play');
    // console.log(key);
    // console.log(ele);
    // if(!key){
    //   ele.play();
    // }
  }

  stop() {
    let videos = document.getElementsByName('video');
    for (let video of videos) {
      console.log(video);
      video.pause();
    }
  }
}

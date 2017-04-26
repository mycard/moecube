/**
 * Created by zh99998 on 16/9/2.
 */
import { Component, Input, OnInit } from '@angular/core';
import { Http } from '@angular/http';
import { Cube } from '../cube';
import { LoginService } from '../login.service';

export interface Points {
  exp: number;
  exp_rank: number;
  pt: number;
  arena_rank: number;
  win: number;
  lose: number;
  draw: number;
  all: number;
  ratio: number;
}

@Component({
  selector: 'cube-arena',
  templateUrl: './cube-arena.component.html',
  styleUrls: ['./cube-arena.component.css'],
})
export class CubeArenaComponent implements OnInit {
  @Input()
  currentCube: Cube;

  points: Points;

  constructor(private http: Http, private loginService: LoginService) {
  }

  async ngOnInit() {
    this.points = await this.http.get('https://moecube.com/ygopro/api/user', { params: { username: this.loginService.user.username } })
      .map((response) => response.json()).toPromise();
  }
}

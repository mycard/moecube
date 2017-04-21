/**
 * Created by weijian on 2016/10/24.
 */
import { Injectable } from '@angular/core';
import { Cube } from './cube';

interface Community {
  id: string,
  url: string
}

@Injectable()
export class RoutingService {
  currentPage = 'lobby';
  currentCube: Cube;
  communities = [
    { id: 'ygopro', url: 'http://ygobbs.com' },
    { id: 'oz', url: 'http://fuckoz.com' }
  ];

  currentCommunity = this.communities[0];
  currentCommunityURL = this.currentCommunity.url;

  navigate(page, item?: Cube | Community, url?) {
    this.currentPage = page;
    switch (page) {
      case 'community':
        if (item) {
          this.currentCommunity = <Community>item;
        }
        if (url) {
          this.currentCommunityURL = url;
        }
        break;
      case 'lobby':
        if (item) {
          this.currentCube = <Cube>item;
        }
        break;
    }
  }

  getCommunity(id) {
    return this.communities.find((item) => item.id === id);
  }
}

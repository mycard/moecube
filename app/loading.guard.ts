import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot } from '@angular/router';
import { CubesService } from './cubes.service';

@Injectable()
export class LoadingGuard implements CanActivate {
  constructor(private router: Router, private cubesService: CubesService) {
  }

  async canActivate(next: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    try {
      await this.cubesService.getCube('ygopro');
      return true;
    } catch (error) {
      this.router.navigate(['/lobby']);
      return false;
    }

  }
}

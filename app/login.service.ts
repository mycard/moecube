/**
 * Created by zh99998 on 2016/10/25.
 */
import {Injectable} from "@angular/core";


/*interface User {
 admin: boolean;
 avatar_url: string;
 email: string;
 external_id: number;
 moderator: boolean;
 name: string;
 username: string;
 }*/

@Injectable()
export class LoginService {
    user = JSON.parse(localStorage.getItem('login'));

    login(user) {
        this.user = user;
        localStorage.setItem('login', JSON.stringify(user));
    }

    logout() {
        this.user = null;
        localStorage.removeItem('login');
    }
}

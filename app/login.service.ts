/**
 * Created by zh99998 on 2016/10/25.
 */
import {Injectable} from "@angular/core";
import {Http} from "@angular/http";


interface User {
    admin: boolean;
    avatar_url: string;
    email: string;
    external_id: number;
    moderator: boolean;
    name: string;
    username: string;
}

@Injectable()
export class LoginService {
    user: User = JSON.parse(localStorage.getItem('login'));
    logging_out;

    constructor(private http: Http) {
    }

    login(user) {
        this.user = user;
        localStorage.setItem('login', JSON.stringify(user));
    }

    logout() {
        this.logging_out = true;
        this.user = null;
        localStorage.removeItem('login');

    }
}
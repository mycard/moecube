/**
 * Created by zh99998 on 2016/10/25.
 */
import {Injectable} from "@angular/core";
import {Http} from "@angular/http";

export interface User {
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
    user: User;
    logged_in = false;
    logging_out = false;

    constructor(private http: Http) {
        let data = localStorage.getItem('login');
        if (data) {
            this.user = JSON.parse(data);
            this.logged_in = true;
        }
    }

    login(user) {
        this.user = user;
        this.logged_in = true;
        localStorage.setItem('login', JSON.stringify(user));
    }

    logout() {
        this.logging_out = true;
        this.logged_in = false;
        localStorage.removeItem('login');

    }
}
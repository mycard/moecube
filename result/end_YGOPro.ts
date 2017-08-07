/**
 * Created by break on 2017/6/9.
 */
import * as $ from 'jquery';

let data_url = (new URL(document.location.toString())).searchParams;
let data_str = data_url.get('data');
console.log(data_str);

// {"usernamea": "loyi",
//     "usernameb": "saten",
//     "userscorea": 2,
//     "userscoreb": 0,
//     "expa": 36.5,
//     "expb": 9,
//     "expa_ex": 35.5,
//     "expb_ex": 8.5,
//     "pta": 479.950607945308,
//     "ptb": 494.012345698275,
//     "pta_ex": 479.950607945308,
//     "ptb_ex": 494.012345698275,
//     "type": "entertain",
//     "start_time": "2017-06-12T17:07:54.000Z",
//     "end_time": "2017-06-12T17:23:16.000Z"}

let data = JSON.parse(data_str!);
let icona = 'https://ygobbs.com/user_avatar/ygobbs.com/' + data.usernamea + '/25/1.png';
let iconb = 'https://ygobbs.com/user_avatar/ygobbs.com/' + data.usernameb + '/25/1.png';

console.log(data);

if (data.usernamea === data.myname) {
    if ( data.userscorea > data.userscoreb) {
        $('#win').show();
    }else if ( data.userscorea < data.userscoreb) {
        $('#lose').show();
    }else {
        $('#a_draw').show();
    }

    $('#myIcon').attr('src', icona);
    $('#myName').html(data.usernamea);
    $('#myScore').html(data.userscorea);
    $('#myExp').html(parseInt(data.expa).toString());
    $('#myGold').html(parseInt(data.pta).toString());

    let tr = '<tr class="myInfo_tr"><td><img src="' + icona + '"></td><td>' + data.usernamea + '</td><td>' + data.userscorea + '</td><td>' + parseInt(data.expa).toString() + '</td><td>' + parseInt(data.pta).toString() + '</td></tr>';
    $('#users_info').append(tr);
    tr = '<tr><td><img src="' + iconb + '"></td><td>' + data.usernameb + '</td><td>' + data.userscoreb + '</td><td>' + parseInt(data.expb).toString() + '</td><td>' + parseInt(data.ptb).toString() + '</td></tr>';
    $('#users_info').append(tr);
}else {
    if ( data.userscorea > data.userscoreb) {
        $('#lose').show();
    }else if ( data.userscorea < data.userscoreb) {
        $('#win').show();
    }else {
        $('#a_draw').show();
    }

    $('#myIcon').attr('src', iconb);
    $('#myName').html(data.usernameb);
    $('#myScore').html(data.userscoreb);
    $('#myExp').html(parseInt(data.expb).toString());
    $('#myGold').html(parseInt(data.ptb).toString());

    let tr = '<tr><td><img src="' + icona + '"></td><td>' + data.usernamea + '</td><td>' + data.userscorea + '</td><td>' + parseInt(data.expa).toString() + '</td><td>' + parseInt(data.pta).toString() + '</td></tr>';
    $('#users_info').append(tr);
    tr = '<tr  class="myInfo_tr"><td><img src="' + iconb + '"></td><td>' + data.usernameb + '</td><td>' + data.userscoreb + '</td><td>' + parseInt(data.expb).toString() + '</td><td>' + parseInt(data.ptb).toString() + '</td></tr>';
    $('#users_info').append(tr);
}

let t = setTimeout(function () {
    window.opener = null;
    window.close();
}, 5000);

$('html').hover(function () {
    clearTimeout(t);
});

// let {ipcRenderer} = require('electron');
// setTimeout( function(){ipcRenderer.send('massage', '')} , 1000);


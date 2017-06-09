/**
 * Created by break on 2017/6/9.
 */
import * as $ from 'jquery';

let data_url = (new URL(document.location.toString())).searchParams;
let data_str = data_url.get('data');
console.log(data_str);
//  data={
//        'win':true,
//        'users_info':[{
//            'isPlay':true,
//            'icon':'http://himg.bdimg.com/sys/portrait/item/55c177633531343132333435f20c.jpg',
//            'name':'刘大耳',
//            'score':'5555',
//            'exp':'123',
//            'gold':'321'
//        },{
//            'isPlay':false,
//            'icon':'http://himg.bdimg.com/sys/portrait/item/55c177633531343132333435f20c.jpg',
//            'name':'关绿帽',
//            'score':'008',
//            'exp':'789',
//            'gold':'999'
//        }
//        ]
//    }
let data = JSON.parse(data_str!);
console.log(data);
let win = data.win;
let users_info = data.users_info;
let my_info;
if (win) {
    $('#win').show();
} else {
    $('#lose').show();
}
console.log(data);

for (let user_info of users_info) {
    let tr_style = '';
    if (user_info.isPlay) {
        tr_style = ' class="myInfo_tr"';
        my_info = user_info;
    }
    let tr = '<tr' + tr_style + '> <td><img src="' + user_info.icon + '"></td><td>' + user_info.name + '</td><td>' + user_info.score + '</td><td>' + user_info.exp + '</td><td>' + user_info.gold + '</td></tr>';
    $('#users_info').append(tr);
}

$('#myIcon').attr('src', my_info.icon);
$('#myName').html(my_info.name);
$('#myScore').html(my_info.score);
$('#myExp').html(my_info.exp);
$('#myGold').html(my_info.gold);

let t = setTimeout(function () {
    window.opener = null;
    window.close();
}, 5000);

$('html').hover(function () {
    clearTimeout(t);
});

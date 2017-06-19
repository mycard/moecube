/**
 * Created by break on 2017/6/9.
 */
import * as $ from 'jquery';

let data_url = (new URL(document.location.toString())).searchParams;
let data_str = data_url.get('data');
// {
//     "usernamea": "Joe1991",
//     "usernameb": "zh99998",
//     "userscorea": 1,
//     "userscoreb": 2,
//     "expa": 1,
//     "expb": 30,
//     "expa_ex": 0.5,
//     "expb_ex": 29,
//     "pta": -2.45677803214143,
//     "ptb": 562.760086898395,
//     "pta_ex": -1.25048918195558,
//     "ptb_ex": 561.553798048209,
//     "type": "athletic",
//     "start_time": "2017-06-17T12:26:33.000Z",
//     "end_time": "2017-06-17T12:26:33.000Z",
//     "winner": "zh99998",
//     "isfirstwin": false,
//     "myname":"zh99998",
//      "athletic_win":23,
//      "athletic_lose":0,
//      "entertain_win":7,
//      "entertain_lose":0,
//      "exp_rank":"1685",
//      "arena_rank":"335",
//      "exp_rank_ex":"1685",
//      "arena_rank_ex":"335",
// }

let data = JSON.parse(data_str!);
let titleStr;
let icon = 'https://ygobbs.com/user_avatar/ygobbs.com/' + data.myname + '/25/1.png';
let myMame = data.myname;
let winTimes, loseTimes, rank, rank_up, DP, DP_up, DP_up_sum, EXP, EXP_up;
let winOrLose = 0;
let isMyFirstWin;

if (data.type === 'entertain') {
    titleStr = '娱乐匹配';
    winTimes = data.entertain_win;
    loseTimes = data.entertain_lose;
    rank = data.exp_rank;
    rank_up = data.exp_rank_ex - data.exp_rank ;
} else {
    titleStr = '竞技匹配';
    winTimes = data.athletic_win;
    loseTimes = data.athletic_lose;
    rank = data.arena_rank;
    rank_up = data.arena_rank_ex - data.arena_rank ;
}


if (data.usernamea === data.myname) {
    if ( data.userscorea > data.userscoreb) {
        winOrLose = 1;
    }else if ( data.userscorea < data.userscoreb) {
        winOrLose = -1;
    }else {
        winOrLose = 0;
    }
    DP = parseInt(data.pta);
    DP_up_sum = Math.floor( data.pta - data.pta_ex );
    EXP = parseInt(data.expa);
    EXP_up = Math.floor( data.expa - data.expa_ex );
}else {
    if ( data.userscorea < data.userscoreb) {
        winOrLose = 1;
    }else if ( data.userscorea > data.userscoreb) {
        winOrLose = -1;
    }else {
        winOrLose = 0;
    }
    DP = parseInt(data.ptb);
    DP_up_sum = Math.floor( data.ptb - data.ptb_ex );
    EXP = parseInt(data.expb);
    EXP_up = Math.floor( data.expb - data.expb_ex );
}
isMyFirstWin = (winOrLose > 0 && data.isfirstwin) ? true : false;
DP_up = DP_up_sum - (isMyFirstWin ? 4 : 0);
// =========================================================================

$('#title').html(titleStr);
$('#icon').attr('src', icon);
$('#myName').html(myMame);


$('#' + (winOrLose ? (winOrLose > 0 ? 'win' : 'lose') : 'draw') ).show();

let tr1 = '<tr>' +
    '<td>胜:<span class="' + (winOrLose > 0 ? 'green' : '') + '">' + winTimes + '</span></td>' +
    '<td>负:<span class="' + (winOrLose < 0 ? 'red' : '') + '">' + loseTimes + '</span></td>' +
    '</tr>';

let tr2 = `<tr>
    <td>排名:<span id="rank" class="${rank_up ? (rank_up > 0 ? 'green' : 'red') : '' } ">${rank}</span></td>
    <td>${data.type === 'entertain' ? 'EXP:' : 'DP:'}
        <span id="EXP_DP" ${data.type === 'entertain' ?
        ('class="' + (EXP_up > 0 ? 'green' : (EXP_up < 0 ? 'red' : '')) + '">' + EXP) :
        ('class="' + (DP_up_sum > 0 ? 'green' : (DP_up_sum < 0 ? 'red' : '')) + '">' + DP)
        }</span>
    </td>
    </tr>`;
$('#info').append(tr1).append(tr2);
let tr_DP = DP_up ? `
    <tr>
    <td>D.P</td>
    ${DP_up > 0 ? `<td class="green">+${ DP_up }</td>` : `<td class="red">${ DP_up }</td>`}
    </tr>
    ` : ``;
let tr_EXP = EXP_up ? `
    <tr>
    <td>EXP</td>
    ${EXP_up > 0 ? `<td class="green">+${ EXP_up }</td>` : `<td class="red">${ EXP_up }</td>`}
    </tr>
    ` : ``;
let tr_FirstWin = isMyFirstWin ? `
    <tr>
    <td>首胜</td>
    <td class="green">+4</td>
    </tr>
    ` : ``

let tr_rewards = tr_EXP + tr_DP + tr_FirstWin;
tr_rewards = tr_rewards === '' ? '<tr><td>无</td></tr>' : tr_rewards;
$('#rewards').append(tr_rewards);


function again() {
    let {ipcRenderer} = require('electron');
    ipcRenderer.send('YGOPro', data.type);
    window.opener=null;
    window.close();
}
let t = setTimeout(function () {
    window.opener = null;
    window.close();
}, 5000);

$('html').hover(function () {
    clearTimeout(t);
});



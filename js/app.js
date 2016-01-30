'use strict';

const ipcRenderer = require('electron').ipcRenderer;
const remote = require('remote');
const current_window = remote.getCurrentWindow();

document.getElementById("minimize").onclick = ()=> {
    current_window.minimize()
};
document.getElementById("maximize").onclick = ()=> {
    current_window.maximize();
};
document.getElementById("restore").onclick = ()=> {
    current_window.unmaximize();
};
document.getElementById("close").onclick = ()=> {
    current_window.close();
};

current_window.on('maximize', ()=> {
    document.body.className = process.platform + ' maximized'
});
current_window.on('unmaximize', ()=> {
    document.body.className = process.platform
});
if (current_window.isMaximized()) {
    document.body.className = process.platform + ' maximized'
} else {
    document.body.className = process.platform
}

window.onhashchange = (event) => {
    let hash = event.newURL.split('#', 2)[1];
    document.getElementsByClassName('active')[0].className = "";
    document.getElementById('nav-' + hash).className = "active";
    document.getElementById(event.oldURL.split('#', 2)[1]).style.display = 'none';
    document.getElementById(hash).style.display = 'block';
};
let hash = location.href.split('#', 2)[1];
document.getElementById('nav-' + hash).className = "active";
document.getElementById(hash).style.display = 'block';

let webviews = document.getElementsByTagName('webview');
for (let i = 0; i < webviews.length; i++) {
    webviews.item(i).addEventListener('new-window', (event) => {
        require('electron').shell.openExternal(event.url);
    });

    /*webviews.item(i).addEventListener('will-navigate', (event) => {
        event.preventDefault()
    });*/
}

document.getElementById("logout").onclick = ()=> {
    current_window.webContents.session.clearStorageData(()=> {
        location.reload();
    })
};
document.getElementById("refresh").onclick = ()=> {
    current_window.webContents.session.clearCache(()=> {
        location.reload();
    })
};

let elements = document.getElementsByClassName('profile');
for (let i = 0; i < elements.length; i++) {
    let element = elements.item(i);
    element.onclick = function () {
        let user_url = 'https://forum.touhou.cc/users/' + document.getElementById('username').innerHTML;
        let user_webview = document.getElementById('forum');
        if (user_webview.src.indexOf(user_url) != 0) { // begin with
            user_webview.src = user_url;
        }
    }
}

ipcRenderer.on('login', (event, user)=> {
    console.log(event, user);
    document.getElementById('avatar').src = user.avatar_url;
    document.getElementById('username').innerHTML = user.username;
    document.getElementById('user').removeAttribute('hidden');
});
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
for (var i = 0; i < webviews.length; i++) {
    webviews.item(i).addEventListener('new-window', (event) => {
        require('electron').shell.openExternal(event.url);
    });
}

document.getElementById("logout").onclick = ()=> {
    current_window.webContents.session.clearStorageData(()=> {
        location.reload();
    })
};

ipcRenderer.on('login', (event, user)=> {
    console.log(event, user);
    document.getElementById('avatar').src = user.avatar_url;
    document.getElementById('username').innerHTML = user.username;
    document.getElementById('user').removeAttribute('hidden');
});
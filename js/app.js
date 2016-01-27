var platform = process.platform;
var remote = require('remote');
var current_window = remote.getCurrentWindow();

document.getElementById("minimize").onclick = function () {
    current_window.minimize()
};
document.getElementById("maximize").onclick = function () {
    current_window.maximize();
};
document.getElementById("restore").onclick = function () {
    current_window.unmaximize();
};
document.getElementById("close").onclick = function () {
    current_window.close();
};

current_window.on('maximize', function () {
    document.body.className = platform + ' maximized'
});
current_window.on('unmaximize', function () {
    document.body.className = platform
});
if (current_window.isMaximized()) {
    document.body.className = platform + ' maximized'
} else {
    document.body.className = platform
}

window.onhashchange = function (event) {
    var hash = event.newURL.split('#', 2)[1];
    document.getElementsByClassName('active')[0].className = "";
    document.getElementById('nav-' + hash).className = "active";
    document.getElementById(event.oldURL.split('#', 2)[1]).style.display = 'none';
    document.getElementById(hash).style.display = 'block';
};
var hash = location.href.split('#', 2)[1];
document.getElementById('nav-' + hash).className = "active";
document.getElementById(hash).style.display = 'block';

var webviews = document.getElementsByTagName('webview');
for (var i = 0; i < webviews.length; i++) {
    webviews.item(i).addEventListener('new-window', function (event) {
        require('electron').shell.openExternal(event.url);
    });
}
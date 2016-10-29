/**
 * System configuration for Angular 2 samples
 * Adjust as necessary for your application needs.
 */
    // map tells the System loader where to look for things
    var map = {
        'app': 'app', // 'dist',
        '@angular': 'node_modules/@angular',
        'angular2-in-memory-web-api': 'node_modules/angular2-in-memory-web-api',
        'rxjs': 'node_modules/rxjs',
        'ng2-translate': 'node_modules/ng2-translate/bundles/index.js',
        "electron": "@node/electron",
        "ini": "@node/ini",
    };
    // packages tells the System loader how to load when no filename and/or no extension
    var packages = {
        'app': {main: 'main.js', defaultExtension: 'js'},
        'rxjs': {defaultExtension: 'js'},
        'angular2-in-memory-web-api': {main: 'index.js', defaultExtension: 'js'}
    };

let builtin_modules = ["buffer", "querystring", "events", "http", "cluster", "zlib", "os", "https", "punycode", "repl", "readline", "vm", "child_process", "url", "dns", "net", "dgram", "fs", "path", "string_decoder", "tls", "crypto", "stream", "util", "assert", "tty", "domain", "constants", "process", "v8", "timers", "console"];
for (let mod of builtin_modules) {
    map[mod] = `@node/${mod}`;
}

    var ngPackageNames = [
        'common',
        'compiler',
        'core',
        'forms',
        'http',
        'platform-browser',
        'platform-browser-dynamic',
        'router',
        'router-deprecated',
        'upgrade',
    ];
    // Individual files (~300 requests):
    function packIndex(pkgName) {
        packages['@angular/' + pkgName] = {main: 'index.js', defaultExtension: 'js'};
    }

    // Bundled (~40 requests):
    function packUmd(pkgName) {
        packages['@angular/' + pkgName] = {main: 'bundles/' + pkgName + '.umd.js', defaultExtension: 'js'};
    }

    // Most environments should use UMD; some (Karma) need the individual index files
    var setPackageConfig = System.packageWithIndex ? packIndex : packUmd;
    // Add package entries for angular packages
    ngPackageNames.forEach(setPackageConfig);
    var config = {
        map: map,
        packages: packages
    };
    System.config(config);

const path = require('path');
module.exports = function (grunt) {
    switch (process.platform) {
        case 'darwin':
            build_prefix = 'Electron.app/Contents/Resources';
            grunt.loadNpmTasks('grunt-appdmg');
            var release_task = 'appdmg';
            break;
        case 'win32':
            build_prefix = 'resources';
            grunt.loadNpmTasks('grunt-electron-installer');
            release_task = 'create-windows-installer';
            break;

    }

    grunt.initConfig({
        clean: ["build"],
        copy: {
            electron: {
                expand: true,
                options: {
                    mode: true,
                    timestamp: true
                },
                cwd: 'node_modules/electron-prebuilt/dist',
                src: '**',
                dest: 'build'
            },
            app: {
                expand: true,
                options: {
                    timestamp: true
                },
                src: ['package.json', 'README.txt', 'LICENSE.txt', 'index.html', 'main.js', 'ygopro.js', 'ygopro/**', 'node_modules/ws/**'],
                dest: path.join('build', build_prefix, 'app')
            }
        },

        electron: {
            osxBuild: {
                options: {
                    name: 'Fixture',
                    dir: 'app',
                    out: 'dist',
                    version: '0.25.3',
                    platform: 'darwin',
                    arch: 'x64'
                }
            }
        },

        'create-windows-installer': {
            x64: {
                appDirectory: 'build',
                outputDirectory: 'release',
                authors: 'MyCard',
                exe: 'electron.exe',
            }/*,
            ia32: {
                appDirectory: 'build/32',
                outputDirectory: 'release/32',
                authors: 'MyCard',
                exe: 'mycard.exe'
            }*/
        }
    });

    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');

    grunt.registerTask('build', ['clean', 'copy:electron','copy:app']);
    grunt.registerTask('release', ['build', release_task]);
    grunt.registerTask('default', ['release']);
};


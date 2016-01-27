'use strict';

const path = require('path');
module.exports = (grunt) => {
    let release_task;
    switch (process.platform) {
        case 'darwin':
            grunt.loadNpmTasks('grunt-appdmg');
            release_task = 'appdmg';
            break;
        case 'win32':
            grunt.loadNpmTasks('grunt-electron-installer');
            release_task = 'create-windows-installer';
            break;
    }

    grunt.initConfig({
        clean: ["build2", "build3", "build4"],
        copy: {
            app: {
                expand: true,
                options: {
                    timestamp: true
                },
                src: ['package.json', 'README.txt', 'LICENSE.txt', 'main.js', 'apps.js', 'bundle.json', '*.tar.xz', 'index.html', 'css/**', 'font/**', 'js/**'],
                dest: 'build2'
            },
            node_modules: {
                expand: true,
                options: {
                    timestamp: true
                },
                cwd: 'build1',
                src: ['node_modules/**', 'bin/**'],
                dest: 'build2'
            }
        },

        electron: {
            win32build: {
                options: {
                    name: 'mycard',
                    dir: 'build2',
                    out: 'build3',
                    platform: 'win32',
                    arch: 'all',
                    icon: 'resources/win/icon.ico'
                }
            }
        },

        'create-windows-installer': {
            x64: {
                appDirectory: 'build3/mycard-win32-x64',
                outputDirectory: 'build4',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win/icon.ico',
                noMsi: true
            }
        }
    });
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-electron');

    grunt.registerTask('build', ['clean', 'copy', 'electron']);
    grunt.registerTask('release', ['build', release_task]);
    grunt.registerTask('default', ['release']);
};

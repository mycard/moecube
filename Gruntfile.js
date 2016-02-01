'use strict';

const path = require('path');
module.exports = (grunt) => {
    let release_task;
    switch (process.platform) {
        case 'darwin':
            grunt.loadNpmTasks('grunt-appdmg');
            release_task = ['electron:darwin', 'appdmg'];
            break;
        case 'win32':
            grunt.loadNpmTasks('grunt-electron-installer');
            release_task = ['electron:win32', 'create-windows-installer:ia32', 'create-windows-installer:x64', 'copy:bundle-ia32', 'copy:bundle-x64', 'create-windows-installer:bundle-ia32', 'create-windows-installer:bundle-x64'];
            break;
    }

    grunt.initConfig({
        clean: ["build2", "build3", "build4-bundle"],
        copy: {
            app: {
                expand: true,
                options: {
                    timestamp: true
                },
                src: ['package.json', 'README.txt', 'LICENSE.txt', 'main.js', 'apps.js', 'index.html', 'css/**', 'font/**', 'js/**'],
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
            },
            'bundle-ia32': {
                expand: true,
                options: {
                    timestamp: true
                },
                cwd: 'bundle',
                src: '**',
                dest: 'build3/mycard-win32-ia32/resources/app'
            },
            'bundle-x64': {
                expand: true,
                options: {
                    timestamp: true
                },
                cwd: 'bundle',
                src: '**',
                dest: 'build3/mycard-win32-x64/resources/app'
            }
        },

        electron: {
            darwin: {
                options: {
                    name: 'mycard',
                    dir: 'build2',
                    out: 'build3',
                    platform: 'darwin',
                    arch: 'all',
                    icon: 'resources/darwin/icon.icns'
                }
            },
            win32: {
                options: {
                    name: 'mycard',
                    dir: 'build2',
                    out: 'build3',
                    platform: 'win32',
                    arch: 'all',
                    icon: 'resources/win32/icon.ico'
                }
            }
        },

        'create-windows-installer': {
            ia32: {
                appDirectory: 'build3/mycard-win32-ia32',
                outputDirectory: 'build4/win32-ia32',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win32/icon.ico',
                noMsi: true
            },
            x64: {
                appDirectory: 'build3/mycard-win32-x64',
                outputDirectory: 'build4/win32-x64',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win32/icon.ico',
                noMsi: true
            },
            'bundle-ia32': {
                appDirectory: 'build3/mycard-win32-ia32',
                outputDirectory: 'build4-bundle/win32-ia32',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win32/icon.ico',
                noMsi: true
            },
            'bundle-x64':{
                appDirectory: 'build3/mycard-win32-x64',
                outputDirectory: 'build4-bundle/win32-x64',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win32/icon.ico',
                noMsi: true
            }
        },
        appdmg: {
            options: {
                title: 'MyCard',
                icon: 'resources/darwin/icon.icns',
                background: 'resources/darwin/TestBkg.png',
                'icon-size': 80,
                contents: [
                    {
                        x: 448,
                        y: 344,
                        type: 'link',
                        path: '/Applications'
                    }, {
                        x: 192,
                        y: 344,
                        type: 'file',
                        path: 'build3/mycard-darwin-x64/mycard.app'
                    }
                ]
            },
            target: {
                dest: 'build4/darwin/mycard.dmg'
            }
        }
    });
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-electron');

    grunt.registerTask('build', ['clean', 'copy:app', 'copy:node_modules']);
    grunt.registerTask('release', ['build'].concat(release_task));
    grunt.registerTask('default', ['release']);
};
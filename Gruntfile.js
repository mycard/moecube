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
            release_task = ['electron:win32-ia32', 'electron:win32-x64', 'create-windows-installer:ia32', 'create-windows-installer:x64', 'copy:bundle-ia32', 'copy:bundle-x64', 'create-windows-installer:bundle-ia32', 'create-windows-installer:bundle-x64'];
            break;
    }

    grunt.initConfig({
        clean: ["build2", "build3", "build4-bundle"],
        copy: {
            'app-ia32': {
                expand: true,
                options: {
                    timestamp: true
                },
                src: ['package.json', 'README.txt', 'LICENSE.txt', 'main.js', 'apps.js', 'index.html', 'css/**', 'font/**', 'js/**'],
                dest: 'build2/win32-ia32'
            },
            'app-x64': {
                expand: true,
                options: {
                    timestamp: true
                },
                src: ['package.json', 'README.txt', 'LICENSE.txt', 'main.js', 'apps.js', 'index.html', 'css/**', 'font/**', 'js/**'],
                dest: 'build2/win32-x64'
            },
            'node_modules-ia32': {
                expand: true,
                options: {
                    timestamp: true
                },
                cwd: 'build1/win32-ia32',
                src: ['node_modules/**', 'bin/**'],
                dest: 'build2/win32-ia32'
            },
            'node_modules-x64': {
                expand: true,
                options: {
                    timestamp: true
                },
                cwd: 'build1/win32-x64',
                src: ['node_modules/**', 'bin/**'],
                dest: 'build2/win32-x64'
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
                    icon: 'resources/osx/icon.icns'
                }
            },
            'win32-ia32': {
                options: {
                    name: 'mycard',
                    dir: 'build2/win32-ia32',
                    out: 'build3',
                    platform: 'win32',
                    arch: 'ia32',
                    icon: 'resources/win/icon.ico'
                }
            },
            'win32-x64': {
                options: {
                    name: 'mycard',
                    dir: 'build2/win32-x64',
                    out: 'build3',
                    platform: 'win32',
                    arch: 'x64',
                    icon: 'resources/win/icon.ico'
                }
            }
        },

        'create-windows-installer': {
            ia32: {
                appDirectory: 'build3/mycard-win32-ia32',
                outputDirectory: 'build4/win32-ia32',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win/icon.ico',
                noMsi: true,
                loadingGif: 'resources/win/setup.gif'
            },
            x64: {
                appDirectory: 'build3/mycard-win32-x64',
                outputDirectory: 'build4/win32-x64',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win/icon.ico',
                noMsi: true,
                loadingGif: 'resources/win/setup.gif'
            },
            'bundle-ia32': {
                appDirectory: 'build3/mycard-win32-ia32',
                outputDirectory: 'build4-bundle/win32-ia32',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win/icon.ico',
                noMsi: true,
                loadingGif: 'resources/win/setup.gif'
            },
            'bundle-x64':{
                appDirectory: 'build3/mycard-win32-x64',
                outputDirectory: 'build4-bundle/win32-x64',
                authors: 'MyCard',
                exe: 'mycard.exe',
                setupIcon: 'resources/win/icon.ico',
                noMsi: true,
                loadingGif: 'resources/win/setup.gif'
            }
        },
        appdmg: {
            options: {
                title: 'MyCard',
                icon: 'resources/osx/icon.icns',
                background: 'resources/osx/TestBkg.png',
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

    grunt.registerTask('build', ['clean', 'copy:app-ia32', 'copy:app-x64','copy:node_modules-ia32','copy:node_modules-x64']);
    grunt.registerTask('release', ['build'].concat(release_task));
    grunt.registerTask('default', ['release']);
};
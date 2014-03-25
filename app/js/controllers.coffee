path = require 'path'
child_process = require 'child_process'

mkdirp = require 'mkdirp'
gui = require 'nw.gui'
Datastore = require('nw_nedb')
db = new Datastore({ filename: path.join(gui.App.dataPath, 'apps.db'), autoload: true });

angular.module('maotama.controllers', [])

.controller 'AppsListController', ($scope)->
    db.find {}, (err, docs)=>
      throw err if err
      $scope.apps = docs
      $scope.$digest();

.controller 'AppsShowController', ['$scope', '$routeParams', ($scope, $routeParams)->
    db.findOne {id: $routeParams.app_id}, (err, doc)->
      throw err if err
      $scope.app = doc;
      console.log $scope.app
      $scope.app.default_installation_path = path.join process.cwd(), 'apps', $scope.app.id
      $scope.app.extra_languages = {}
      for lang, download of $scope.app.languages
        console.assert $scope.app.download.url
        console.assert $scope.app.download.size
        if download != true
          $scope.app.has_extra_languages = true
          $scope.app.extra_languages[lang] = download

      $scope.installing = {};

      $scope.$digest();



    $scope.add = (installation)->
      $scope.app.installation = path.dirname installation
      db.update {
        id: $scope.app.id
      }, {
        $set: {
          installation: $scope.app.installation
        }
      }, (err, numReplaced, newDoc)->
        throw err if err

        $scope.$digest();

    $scope.install = ()->
      $scope.installing[$scope.app.id] =
        process: 0
        label: '正在连接'
      mkdirp path.join(process.cwd(), 'cache'), (err)->
        throw err if err
        aria2c = child_process.spawn 'bin/aria2c', ["--dir=cache", "--enable-color=false", "-c", $scope.app.download.url]
        aria2c.stdout.setEncoding('utf8');
        aria2c.stderr.setEncoding('utf8');
        aria2c.stdout.on 'data', (data)->
          console.log data
          #[#06c774 35MiB/298MiB(11%) CN:1 DL:62MiB ETA:4s]
          if matches = data.match(/\[(?:#\w+ )?(\w+)\/(\w+)\((\d+)%\) CN:(\d+) DL:(\w+) ETA:(\w+)\]/)
            [d, downloaded, total, progress, connections, speed, eta] = matches
            $scope.installing[$scope.app.id].progress = progress
            $scope.installing[$scope.app.id].label = "#{progress}% #{speed}/s"
            $scope.$digest();

        aria2c.stderr.on 'data', (data)->
          console.log 'err: ', data
        aria2c.on 'close', (code)->
          if code == 0
            $scope.installing[$scope.app.id].progress = 100
            $scope.installing[$scope.app.id].label = '正在安装'
            $scope.$digest();
            p = path.join "apps/#{$scope.app.id}"
            mkdirp p, (err)->
              throw err if err
              console.log ["x", "-y", "-o#{p}", "cache/#{path.basename($scope.app.download.url)}"]
              console.log p7zip = child_process.spawn 'bin/7za', ["x", "-y", "-o#{p}", "cache/#{path.basename($scope.app.download.url)}"]
              p7zip.stdout.setEncoding('utf8');
              p7zip.stderr.setEncoding('utf8');
              p7zip.stdout.on 'data', (data)->
                console.log data
              p7zip.stderr.on 'data', (data)->
                console.log 'err: ', data
              p7zip.on 'close', (code)->
                console.log code
                if code == 0
                  delete $scope.installing[$scope.app.id]
                  $scope.add path.join(p, $scope.app.main)
                else
                  throw "安装失败: #{code}"
          else
            throw "下载失败: #{code}"

    $scope.run = ()->
      console.log $scope.app
      $scope.app.running = true
      child_process.execFile $scope.app.main,
        cwd: $scope.app.installation
      , (error, stdout, stderr)->
        throw error if error
        $scope.app.running = false
        $scope.$digest();
]


if false #for debug
  db.remove {}, { multi: true }, (err, numRemoved)->
    throw err if err
    db.insert [{
      "id":"th135",
      "category":"game",
      "name":"东方心绮楼",
      "network":{
        "proto":"udp",
        "port":10800
      },
      "main":"th135.exe",
      "summary":"喵喵喵喵喵帕斯
      nyanpass nyanpass"
      "download": {
        "url": "http://test2.my-card.in/downloads/maotama/th135_1.33.7z"
        "size": 313177239
      }
      "main": 'th135.exe'
      "languages": {
        "ja-JP": true
        "zh-CN": {
          url: "http://test2.my-card.in/downloads/maotama/th135_lang_zh-CN_1.33.7z"
          size: 74751963
        }
      }
    },{
      "id":"th123",
      "category":"game",
      "name":"东方非想天则",
      "network":{
        "proto":"udp",
        "port":10800
      },
      "summary":"",
      "download": {
        url: "http://test2.my-card.in/downloads/maotama/th123_1.10a.7z"
        "size": 313177239
      },
      "main": 'th123.exe'
      "languages": {
        "ja-JP": true
      }

    }], (err, newDocs)->
      throw err if err
      console.log newDocs
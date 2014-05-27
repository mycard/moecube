path = require 'path'
fs = require 'fs'
child_process = require 'child_process'
crypto = require 'crypto'

mkdirp = require 'mkdirp'
rmdir = require 'rmdir'
gui = require 'nw.gui'
Datastore = require 'nw_nedb'

tunnel = require './js/tunnel'

db =
  apps: new Datastore({ filename: path.join(gui.App.dataPath, 'apps.db'), autoload: true })
  local: new Datastore({ filename: path.join(gui.App.dataPath, 'local.db'), autoload: true })
  profile: new Datastore({ filename: path.join(gui.App.dataPath, 'profile.db'), autoload: true })
  user: new Datastore({ filename: path.join(gui.App.dataPath, 'user.db'), autoload: true })
angular.module('maotama.controllers', [])
.controller 'AppsListController', ['$scope', '$routeParams', '$http', '$location', ($scope, $routeParams, $http, $location)->
    $scope.orderProp = 'id';
    $http.get('apps.json').success (data)->
      db.apps.remove {}, { multi: true }, (err, numRemoved)->
        throw err if err
        db.apps.insert data, (err, newDocs)->
          throw err if err
          $scope.apps = data
          if !$routeParams.app_id
            $location.path("/apps/#{data[0].id}");
            $scope.$apply()
          else
            $scope.$digest()

    $scope.active = (app_id)->
      "active" if $routeParams.app_id == app_id
    $scope.category_active = (category)->
      if $scope.apps
        app = null
        for a in $scope.apps
          if a.id == $routeParams.app_id
            app = a
        if app
          if app.category == category
            "active"
]
.controller 'AppsShowController', ['$scope', '$routeParams','$rootScope', ($scope, $routeParams, $rootScope)->
    $scope.tunnel_servers = require './tunnel_servers.json'
    $scope.candy = document.getElementById('candy')
    db.apps.findOne {id: $routeParams.app_id}, (err, doc)->
      throw err if err
      $scope.app = doc
      $scope.runtime =
        running: false
        installing: {}
      $scope.default_installation_path = path.join process.cwd(), 'apps', $scope.app.id

      db.local.findOne {id: $routeParams.app_id}, (err, doc)->
        $scope.local = doc ? {}
        db.profile.findOne {id: $routeParams.app_id}, (err, doc)->
          if doc #and doc.achievements.length == $scope.app.achievements.length
            $scope.profile = doc
            $scope.$digest();
          else
            $scope.profile =
              id: $routeParams.app_id
              achievements: ([] for achievement in $scope.app.achievements) if $scope.app.achievements
            db.profile.insert $scope.profile, (err, newDoc)->
              throw err if err
              $scope.$digest();

    $scope.add = (installation)->
      $scope.local.installation = path.dirname installation
      db.local.update {
        id: $scope.app.id
      }, {
        $set: {
          installation: $scope.local.installation
        }
      }, {
        upsert: true
      }, (err, numReplaced, newDoc)->
        throw err if err
        $scope.$digest();
    $scope.install = ()->
      $scope.runtime.installing[$scope.app.id] =
        process: 0
        label: '正在连接'
      mkdirp path.join(process.cwd(), 'cache'), (err)->
        throw err if err
        aria2c = child_process.spawn 'bin/aria2c', ["--check-integrity", "--checksum=md5=#{$scope.app.download.checksum}", "--dir=cache", "--enable-color=false", "-c", $scope.app.download.url]
        aria2c.stdout.setEncoding('utf8');
        aria2c.stderr.setEncoding('utf8');
        aria2c.stdout.on 'data', (data)->
          console.log data
          #[#06c774 35MiB/298MiB(11%) CN:1 DL:62MiB ETA:4s]
          #[#d1b179 752KiB/298MiB(0%) CN:1 DL:109KiB ETA:46m17s]
          #[#4dd4a5 592KiB/298MiB(0%) CN:1 DL:43KiB ETA:1h57m19s]
          if matches = data.match(/\[(?:#\w+ )?([\w\.]+)\/([\w\.]+)\((\d+)%\) CN:(\d+) DL:([\w\.]+) ETA:(\w+)\]/)
            [d, downloaded, total, progress, connections, speed, eta] = matches
            $scope.runtime.installing[$scope.app.id].progress = progress
            $scope.runtime.installing[$scope.app.id].label = "#{progress}% #{speed}/s"
            $scope.$digest();

        aria2c.stderr.on 'data', (data)->
          console.log 'err: ', data
        aria2c.on 'close', (code)->
          if code != 0
            window.LOCAL_NW.desktopNotifications.notify $scope.app.icon, $scope.app.name, "下载失败, 错误: #{code}"
            delete $scope.runtime.installing[$scope.app.id]
            $scope.$digest();
          else
            $scope.runtime.installing[$scope.app.id].progress = 100
            $scope.runtime.installing[$scope.app.id].label = '正在安装'
            $scope.$digest();

            downloaded = "cache/#{path.basename($scope.app.download.url)}";

            # 二次校验，如果aria2c被强制退出了，返回码也是0
            checksum = crypto.createHash('md5');
            file = fs.ReadStream(downloaded);
            file.on 'data', (d)->
              checksum.update(d)

            file.on 'end', ()->
              if checksum.digest('hex') != $scope.app.download.checksum
                window.LOCAL_NW.desktopNotifications.notify $scope.app.icon, $scope.app.name, "校验错误"
                delete $scope.runtime.installing[$scope.app.id]
                $scope.$digest();
              else
                p = path.join "apps/#{$scope.app.id}"
                mkdirp p, (err)->
                  throw err if err
                  console.log ["x", "-y", "-o#{p}", downloaded]
                  console.log p7zip = child_process.spawn 'bin/7za', ["x", "-y", "-o#{p}", "cache/#{path.basename($scope.app.download.url)}"]
                  p7zip.stdout.setEncoding('utf8');
                  p7zip.stderr.setEncoding('utf8');
                  p7zip.stdout.on 'data', (data)->
                    console.log data
                  p7zip.stderr.on 'data', (data)->
                    console.log 'err: ', data
                  p7zip.on 'close', (code)->
                    if code != 0
                      window.LOCAL_NW.desktopNotifications.notify $scope.app.icon,  $scope.app.name, "安装失败, 错误: #{code}"
                      delete $scope.runtime.installing[$scope.app.id]
                      $scope.$digest();
                    else
                      delete $scope.runtime.installing[$scope.app.id]
                      window.LOCAL_NW.desktopNotifications.notify $scope.app.icon, $scope.app.name, '安装完成'
                      $scope.add path.join(p, $scope.app.main)
    $scope.uninstall = ()->
      $scope.runtime.uninstalling = true
      db.local.remove {
        id: $scope.app.id
      }, (err, numRemoved)->
        throw err if err
        rmdir $scope.local.installation, ( err, dirs, files )->
          console.log dirs
          console.log files
          console.log 'all files are removed'
          $scope.local = {}
          $scope.$digest()

    $scope.run = ()->
      $scope.runtime.running = true
      $scope.candy.contentWindow.postMessage(type: 'status', status: "正在玩 #{$scope.app.name}", show: "dnd" , $scope.candy.src)
      if $scope.app.id is "efz"
        game = child_process.spawn "cmd.exe", ["/c", $scope.app.main],
          cwd: $scope.local.installation
      else
        game = child_process.spawn $scope.app.main, ["--maotama-username=#{$rootScope.current_user.name}",
          "--maotama-ranking-#{$rootScope.current_user.name}=#{$scope.profile.score}",
            "--maotama-ranking-博丽灵梦=6500",
            "--maotama-ranking-♂Van♂=5800",
            "--maotama-ranking-比利♂海灵顿=5600",
            "--maotama-ranking-德国Boy=5430",
            "--maotama-ranking-麦当劳叔叔=5400",
            "--maotama-ranking-村口王师傅=5200",
            "--maotama-ranking-帝国元首=4800",
            "--maotama-ranking-葛老师=3600",
            "--maotama-ranking-五道杠大队长=3300",
          ],
          cwd: $scope.local.installation
      game.stdout.setEncoding('utf8');
      game.stdout.on 'data', (data)->
        console.log data
        if matches = data.match /<maotama>(.+)<\/maotama>/
          for command in $(matches[1])
            switch command.tagName
              when 'ACHIEVEMENT'
                achievement = $scope.app.achievements[$(command).attr('type')]
                achievement_item = achievement.items[$(command).attr('id')]

                $scope.profile.achievements[$(command).attr('type')] ?= {}
                return if $scope.profile.achievements[$(command).attr('type')][$(command).attr('id')]

                window.LOCAL_NW.desktopNotifications.notify achievement_item.icon, "获得#{achievement.name}: #{achievement_item.name}", achievement_item.description
                $scope.profile.achievements[$(command).attr('type')][$(command).attr('id')] =
                  created_at: new Date()
                  updated_at: new Date()
                  count: 1
                db.profile.update {
                  id: $scope.app.id
                }, $scope.profile, (err, numReplaced, newDoc)->
                  throw err if err
                  $scope.$digest();
              when 'SCORE'
                score = parseInt $(command).text()
                if !$scope.profile.score or score > $scope.profile.score
                  window.LOCAL_NW.desktopNotifications.notify $scope.app.icon, "最高得分", score
                  $scope.profile.score = score
                  db.profile.update {
                    id: $scope.app.id
                  }, $scope.profile, (err, numReplaced, newDoc)->
                    throw err if err
                    $scope.$digest();
                else
                  window.LOCAL_NW.desktopNotifications.notify $scope.app.icon, "unknown command", matches[1]
      game.on 'close', (code)->
        $scope.runtime.running = false
        $scope.candy.contentWindow.postMessage(type: 'status', $scope.candy.src)
        $scope.$digest();

    $scope.achievement_unlocked_count = (category)->
      $scope.profile.achievements[category].length
    $scope.achievement_total_count = (category)->
      $scope.app.achievements[category].items.length
    $scope.achievement_last_unlocked = (category)->
      last = null
      last_index = null
      for index, achievement of $scope.profile.achievements[category]
        if !last or result.created_at < last.created_at
          last = achievement
          last_index = index
      $scope.app.achievements[category].items[index]

    $scope.achievement_locked = (category, index)->
      if $scope.profile.achievements[category][index]
        ''
      else
        'locked'

    $scope.tunnel = (server = $scope.tunnel_servers[0])->
      $scope.runtime.tunnel_server = server
      $scope.runtime.tunneling = true
      $scope.runtime.tunnel = null

      tunnel.listen $scope.app.network.port, server.url, (address)->
        $scope.runtime.tunneling = false
        $scope.runtime.tunnel = address
        $scope.$digest()

]

.controller 'UserController', ['$scope','$rootScope', '$http', ($scope, $rootScope, $http)->
    db.user.findOne {}, (err, doc)->
      $rootScope.current_user = doc
      $scope.$digest()

    $scope.sign_in = (user)->
      $scope.signing = true
      $http.get 'http://my-card.in/users/me.json',
        params: user
      .success (data)->
        $scope.signing = false
        if data == 'true'
          $rootScope.current_user = {
            name: user.name
            password: user.password
          }
          if user.remember_me
            db.user.update {}, user, {upsert: true}, (err)->
              throw err if err

        else
          alert '登录失败'
    $scope.sign_out = ()->
      $rootScope.current_user = null
      $scope.$apply()
      db.user.remove {}, (err)->
        throw err if err

    $scope.candy_url = ()->
      "candy/index.html?bosh=http://localhost:5280/http-bind&jid=#{encodeURIComponent $rootScope.current_user.name}@my-card.in&password=#{encodeURIComponent $rootScope.current_user.password}" if $rootScope.current_user
]
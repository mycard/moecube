# 毛玉

这是一个正在开发中的ACG同人向游戏平台

毛玉只是开发代号，不作为最终名称，可能会并入mycard

## 要解决的问题
* 找资源(本体、更新补丁、语言包)繁琐，尤其是过时资源
* 在中国大陆即使想购买正版也很难买到
* 独立游戏作者没有渠道发布游戏
* (需要联机的游戏)跨运营商互访困难、没有公网IP
* 需要手动下载安装vc++运行时、DirectX运行时等依赖项，这个并不是所有人都会的
* 有些游戏甚至要配置一下才能用，例如东方心绮楼需要玩家手动在目录下建立个network_history的文件才能进行联机；要起英文以外的profile名字必须手动改文件；要换头像必须手动改文件
* 存档和个人资料同步(例如非想天则玩家卡组)
* 有些游戏原生不支持某些平台，但是有办法能调教起来，例如东方大多数游戏可以用wine在Linux/OSX下运行
* 有些游戏系统需要依赖网络实现(例如成就)，而游戏作者可能并不擅长这个
* 社交、战绩统计

## 功能列表 (发布之前)
* 用户登录
* 聊天
* 自动更新
* 进程单实例

以下功能至少支持东方绯想天、非想天则、心绮楼
* 下载
* 基于服务器转发的联机 (反重力场)  (已实现一份windows-only的。windows-only纯粹因为提权，其他平台可以用setuid之类的办法更容易实现，不用弹提权确认窗)
* 语言切换 (考虑一下语言包怎么定义，可能还会有其他MOD? DLC? 暂时想不到什么)
* profile名称修改 (注意泛用性，抽个接口，before_run之类。还有FXTZ/FXT合体)

## 想到的功能列表 (有生之年)
### 首页
* 公告
* 推荐
* 捐款

### 游戏
* 自动匹配对战
* 好友约战
* (对于有定制规则的游戏) 基于房间的自定义游戏 大厅
* replay管理
* 排行榜
* 收集 (成就、符卡等)
* 游戏内个人信息(头像等?)
* 存档同步
* 自动更新
* 一定程度的跨平台，例如能wine起来的游戏就直接标记为支持linux、mac。下载的时候一起调教好。
* 依赖 (dx, c++runtime, linux系统源, 黑历史的PC98模拟器之类，还有FXTZ->FXT的建议性依赖)

### 游戏和其他资源
* 好友玩过/好友正在玩
* 评论
* 评分
* 社交分享(需要么)
* (漫画)弹幕(需要么)
* 删除

## 资源打包格式
如果不是原作者亲自发布的，要注意官方发布的版本有哪些文件就只带那些，不要夹带私货
对于给用户看的文本文件，以UTF-8无BOM编码来保存
文件压缩为7z格式，不要封一层目录，散着放进来。压缩选项文件列表UTF-8编码 ( -scsUTF-8 )， 其余默认
对于语言包，如果翻译了原本的文本文件，直接原始文件名(history.txt ， 而不是history(zh).txt)。而资源和可执行文件按翻译组的意见(th123_beta.exe)

## 目录结构

    app/                --> 代码和资源
      css/              --> 样式表
      img/              --> 图片
      index.html        --> 页面
      js/               --> javascript files
        app.js          --> application
        controllers.js  --> angular controllers 主要逻辑在这里
        directives.js   --> angular directives 还不会玩
        filters.js      --> angular filters 在模板里调用的函数
        services.js     --> angular services 还不会玩
      lib/              --> 三方库
      partials/         --> angular view partials 模板
        app_show.html   --> 游戏的模板

    bin/            --> 二进制文件，平台相关，不入git
      7za.exe       --> http://7-zip.org/download.html zip 
      aria2c.exe    --> http://aria2.sourceforge.net/
      node.exe      --> http://nodejs.org/ UAC提权时候用
      nw.exe        --> https://github.com/rogerwang/node-webkit
    maotama.exe     --> 给用户调用的主程序，winrar自解压 静默 "bin\nw.exe" .

    LICENSE        --> 许可证 AGPL
    README.md      --> 本文档

    apps.json       --> 调试用数据库，生产时应当在服务器上
    loop_start.bat  --> 调试用循环启动，叉掉之后自动开启一个新实例

二进制文件可以在 http://test2.my-card.in/downloads/maotama/maotama_win32_binaries.7z 下载

## 数据定义
  应用

    id                      --> 必填, 标识符，通常是英文简称，由小写字母、数字、下划线组成
    category              --> 必填, 应用类型
      category: game          --> 游戏，以及其他不方便归类的可执行程序
      category: audio         --> 音频，音乐等
      category: video         --> 视频，动画等
      category: graphics      --> 静态图片，漫画等
      category: book          --> FanBook、小说等
      category: development   --> 开发者相关，通常是运行时依赖项，例如 DirectX
    name                  --> 必填, 应用名称  //TODO: i18n
    network               --> 如果应用需要反重力场功能，在这里填写网络相关信息
      protocol            --> 协议，必须为udp
      port                --> 默认端口
    main                  --> 主程序文件名 //TODO: 跨平台
    summary               --> 应用介绍
    download              --> 必填, 下载信息
    languages             --> 语言的数组，语言是像zh-CN这样的字符串
    mods                  --> 附加模块的数组. mods和dependencies的区别是，mods必须依赖于应用本体而存在，dependencies可以独立存在，可以为多个应用服务
      name                --> 对于type=language以外必填, 名称 //TODO: i18n
      type                --> 必填, 模块类型
        type: language    --> 语言包
        type: dlc         --> DLC
      languages           --> type=language时必填,语言的数组
      override_main       --> 覆盖应用的入口程序
      main                --> mod自己的入口程序
      download            --> 必填,下载信息
    dependencies          --> 相关资源
      id                  --> 必填,id
      type                --> 必填,依赖类型
        type: require     --> 必需依赖 例如 DirectX //TODO: 跨平台
        type: optional    --> 可选依赖 例如 th123 -> th135
    achievements          --> 收集要素的数组
      name                --> 收集要素名称，例如 【成就】、【符卡】
      type                --> 必填，收集要素类型
        type:unlock       --> 解锁
      items               --> 必填，具体的收集要素项目的数组
        icon              --> 必填，图标的url，协议必须是http、https之一
        name              --> 必填，标题
        description       --> 介绍

  下载信息

    url                     --> 必填，协议必须是http、https、ftp之一
    size                    --> 必填，文件大小，字节数
    checksum                --> 必填，md5校验码



## API
* XMPP my-card.in
* XMPP聊天室 conference.my-card.in
* 以下全都为临时，开发用
* 用户认证 https://my-card.in/users/me.json?name=用户名&password=密码
* 反重力场 ws://122.0.65.69:10800/
* 应用列表 (本地app目录) apps.json
* 应用元文件 (本地app目录) meta

## 相关技术

* nodejs
* node-webkit
* HTML5
* AngularJS
* XMPP


## 制作组

* +神楽坂玲奈 <zh99998@gmail.com>
* +艾可 <arzusyume@gmail.com>

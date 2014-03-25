# 毛玉

这是一个正在开发中的ACG同人向游戏平台

毛玉只是开发代号，不作为最终名称，可能会并入mycard

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

## API
* XMPP my-card.in
* XMPP聊天室 conference.my-card.in
* 以下全都为临时，开发用
* 用户认证 https://my-card.in/users/me.json?name=用户名&password=密码
* 反重力场 ws://122.0.65.69:10800/
* 资源列表 https://github.com/mycard/maotama/raw/master/apps.json
* 资源下载 http://test2.my-card.in/downloads/maotama/

## 相关技术

* nodejs
* node-webkit
* HTML5
* AngularJS
* XMPP


## 制作组

* +神楽坂玲奈 <zh99998@gmail.com>
* +艾可 <arzusyume@gmail.com>

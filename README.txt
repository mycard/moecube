== mycard

这是一个游戏王对战器，与ygocore协议兼容

快捷键：
F12 返回上一层

常见问题：

Q：登陆时显示“解析服务器失败”怎么办？ 
A：如果是以Mycard用户登陆的话，请在登陆时去掉用户名中「@」后的内容。 Gmail用户请将DNS修改成8.8.8.8 208.67.222.222。

Q：为什么打完一局后换side时会无反应？&为什么经常提示内存不能为read？&为什么我的游戏的帧率(左上角的数字)极低？ 
A:可尝试用记事本打开mycard\ygocore\中的system.conf文件，找到use_d3d，其后边的数值原来是0就改成1，原来是1就改成0。或下载“驱动精灵”更新显卡驱动。

更多常见问题请到 https://forum.my-card.in/faq

作者联系方式：
1. mycard的论坛 https://forum.my-card.in
2. E-mail/QQ/GT: zh99998@gmail.com


# 歇斯底里2一键搭建脚本

这个仓库包含了一个为歇斯底里协议设计的一键搭建脚本。
```markdown
同时也提供了windows适用的一键配置生成脚本，你只需要同步输入相关信息
务必检查信息输入正确性
```


### 脚本信息
- 作者：rei
- 兼容性：Debian 8+

### 操作说明

在运行脚本运行开始时，输入yes表示您再次确认认同并确认遵守免责声明并继续执行本脚本。

脚本将执行以下操作：
1. 更新你的软件包列表。
2. 安装 curl 和 sudo。
3. 从官方源下载并执行歇斯底里搭建脚本。
4. 为歇斯底里服务器生成自签名的TLS证书并设置必要的权限。
5. 提示你为歇斯底里服务输入一个自定义端口。
6. 提供设置自定义密码的选项。
7. 输出所选择的端口和密码，并使用它们配置歇斯底里服务器。
8. 启动歇斯底里服务器服务并显示其状态。

### 自定义

你将被提示输入一个端口和设置自定义密码的选项。如果没有提供自定义密码，将使用默认密码。
```markdown
请尽可能使用自定义密码
```

### 使用方法

要使用这个脚本，请将以下命令粘贴到你的终端中并按提示操作：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ImproveRei0/hysteria2_build/main/build.sh)
```
或者使用下面英文版本以解决部分ssh链接中文乱码问题

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ImproveRei0/hysteria2_build/main/build_en.sh)
```

请注意，这个脚本是为熟悉终端操作和网络协议的高级用户设计的。

注意：脚本需要最基本的执行权限

###免责声明:
- 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
- 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。

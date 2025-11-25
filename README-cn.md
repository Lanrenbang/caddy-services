# caddy-services
[英文](README.md) | [简体中文](README-cn.md)

以安全/简单的方式使用 Caddy；你的配置文件无需任何隐藏处理即可随意分享，甚至使用机密支持后，你的环境变量配置也可随意分享。

## 功能
- 配置文件实现自动变量替换；
- 环境变量支持机密，如 Docker/Podman secrets 等；
- 自动跟踪上游更新并构建镜像；
- 提供开箱即用的配置模板，默认支持 Xray-core/xray-api-bridge 等上游服务；
- 配置模板默认集成 L4 反代、JWT 身份验证等模块，完全可充当 API 网关角色；
- 提供 Docker/Podman build/compose 配置，通过简单配置可实现本地自定义构建任何 caddy 模块；

## 项目结构
```shell
.
├── services                        # 子服务推荐存储点
├── site                            # caddy 静态站点
│   └── web
│       └── index.html
├── templates
│   └── Caddyfile.json.template     # caddy 配置模板
├── .env.warp.example               # 模板替换定义
├── .modules                        # caddy 模块定义
├── compose.yaml                    # 容器编排配置
├── compose.override.yaml           # 容器覆盖配置 - 子服务专用
├── Dockerfile                      # 镜像生成配置
├── HEALTHCHECK.md                  # 健康检查说明
├── README.md
└── README-cn.md
```
> 注意：我们直接采用 json 配置而不是 caddy 默认更精简的 Caddyfile；
这是因为与 L4 模块搭配时后者会自动生成部分冗余配置，且更主要的是 Caddyfile 仅支持为明确声明的域名站点块自动配置证书，但我们的配置中根本不需要这样的站点块。

## 用法
1. 自行安装 Docker 或者 Podman（推荐），也可以选择本机运行；
2. 克隆本仓库：
```shell
git clone https://github.com/Lanrenbang/caddy-services.git
```
> 也可下载 [Releases](https://github.com/Lanrenbang/caddy-services/releases) 档案
3. 复制或更名 [.env.warp.example](.env.warp.example) 为 `.env.warp`，按需修改必要内容；
4. 参考内部注释按需修改 [compose.yaml](compose.yaml)/[compose.override.yaml](compose.override.yaml)；
5. 将上一步配置为机密的信息加入密钥：
```shell
echo -n "some secret" | docker secret create <secret_name> - 
echo -n "some secret" | podman secret create <secret_name> - 
```
> 或者直接运行 `docker/podman secret create <secret_name>`，然后根据提示输入密钥；

> **注意：**`<secret_name>` 必须在 `.env.warp`、`compose.yaml` 相关文件中保持一致！
6. 进入根目录后，启动容器服务：
```shell
docker compose up -d
podman compose up -d
```

## 关于模块
- 检查 [.modules](.modules) 模块配置文件，如果本项目提供的模块不符合你的预期，需要按需修改且无法使用本项目提供的远程镜像；
- 在重新定义需要的模块后，可以使用随附的 Dockerfile 轻松的构建本地自定义镜像使用；
- 当然你也可以上传到自己的镜像仓库，具体参考项目的 GitHub 工作流配置。

## 其他
- caddy 本身是支持占位符（可理解为变量）的，但并非所有字段都支持，尤其是各种模块的支持程度并不一致，因此本项目采用 [envwarp](https://github.com/Lanrenbang/envwarp) 小工具在运行前实现变量替换；
- 模块配置文件中提供了缓存模块的描述参考，但本项目当前未使用，如有需求，请自行研究；
- 如果不希望使用容器，在本机环境运行本项目，请参考 [本机运行指南](https://github.com/Lanrenbang/xray-services/blob/main/systemd/README.md)；
- 关于容器健康检查，请参考 [HEALTHCHECK 说明](HEALTHCHECK.md)

## 相关项目
- [xray-services](https://github.com/Lanrenbang/xray-services)
- [xray-api-bridge](https://github.com/Lanrenbang/xray-api-bridge)

## 鸣谢
- [caddy](https://github.com/caddyserver/caddy)

## 通过捐赠支持我
[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/bobbynona) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/bobbynona) [![USDT(TRC20)/Tether](https://img.shields.io/badge/Tether-168363?style=for-the-badge&logo=tether&logoColor=white)](https://github.com/bobbynona/bobbynona/blob/c9f5b7482b4a951bd40a5f4284df41c0627724b8/USDT-TRC20.md) [![Litecoin](https://img.shields.io/badge/Litecoin-A6A9AA?style=for-the-badge&logo=litecoin&logoColor=white)](https://github.com/bobbynona/bobbynona/blob/c9f5b7482b4a951bd40a5f4284df41c0627724b8/Litecoin.md)

## 许可
本项目按照 `LICENSE` 文件中的条款进行分发。

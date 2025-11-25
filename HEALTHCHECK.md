关于容器健康检查

健康检查（不是 caddy 内置的健康检查功能）对于容器标准化使用是非常有意义的。但项目中并未提供，这主要是考虑到 podman 兼容性问题。

1、你可以在任意 compose.yaml 中加入健康检查逻辑：
```
    healthcheck:
      test: ["CMD", "envsubst-warp", "check", "http://127.0.0.1/healthcheck"]
      interval: 10m
      timeout: 5s
      retries: 3
      start_period: 15s
```
我们的变量替换工具 envwarp 内置 check 用于健康检查，其参数检查地址可以不提供，此时使用 `ENVWARP_CHECKURL` 环境变量作为回退；
注意 test 检查命令必须以 exec 形式（也就是数组）提供，否则在 distroless 镜像中因为无 shell 无法执行；
但以上，在 podman-compose 环境中并不能正确执行，这是因为其内置缺陷会将 CMD 自动替换为 CMD-SHELL，也就是需要 `/bin/sh` shell 环境。
解决方案是要么不使用 distroless 镜像（其 debug 版本带 /bin/sh），要么在构建阶段定义健康检查。

2、构建阶段 Dockerfile ，你可以在最终镜像部分，比如 ENTRYPOINT 之前加入：
```
HEALTHCHECK --interval=10m --timeout=5s --start-period=15s \
    CMD [ "/usr/local/bin/envwarp", "check", "http://127.0.0.1/healthcheck" ]
```
注意，如果你设置了这些并且要使用 podman 构建镜像，则必须使用： 
`podman build --layers --format docker --tag caddy-custom .`
类似这样的构建命令，--layers 默认开启可以省略，关键是 --format docker 指示构建为 docker 格式镜像而不是默认的 OCI 格式，否则 HEALTHCHECK 指令不会生效且会发出警告！
如果检查地址并不能在构建阶段确定，可以使用上述的环境变量方式传递；
这样构建后不会依赖 shell 执行健康检查，你依然可以在 compose.yaml 中配置 healthcheck 的其他参数，但“不能”改写 `test` 选项，否则再次回到上一步的问题；
题外话：如果你确定不使用任何健康检查，也可以在构建阶段使用 `HEALTHCHECK NONE` 禁止任何依赖镜像传递来的健康检查设置。

3、即使使用上述方案，你可能还无法使用健康检查，这取决于你的宿主机是否是 systemd 环境，非 systemd 系统（比如 Alpine），依旧不能定时执行健康检查。
结果是你的容器一直处于 `starting` 状态，此时你可以手动执行 `podman healthcheck run <容器名称>`，才能看到正确的 healthy 状态。
你可以建立系统定时任务，自动执行上述命令，来解决 `podman 在非 systemd 系统无法执行健康检查` 的问题，但这超出了项目兼容性，因此默认没有提供任何健康检查设置。
参考： [#19381](https://github.com/containers/podman/discussions/19381)

4、后续，如果你使用 docker 而不是 podman 则没有上述限制，因为 docker 依赖守护进程运行，会自动触发健康检查。
如果你启用了健康检查，可以在任何 compose.yaml 中对服务依赖进行进一步限定，比如让 xray 服务仅在 caddy 确定健康时才启动：
```
    depends_on:
      caddy:
        condition: service_healthy
        restart: true
```
这是健壮的多容器环境中非常推荐的解决方案。

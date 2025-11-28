# caddy-services
[English](README.md) | [Simplified Chinese](README-cn.md)

Use Caddy in a secure and simple way. Your configuration files can be shared freely without redaction. With secrets support, even your environment variable configurations can be shared safely.

## Features
- Automatic variable substitution in configuration files.
- Support for secrets in environment variables (e.g., Docker/Podman secrets).
- Automatically tracks upstream updates and rebuilds images.
- Provides out-of-the-box configuration templates, with default support for upstream services like Xray-core and xray-api-bridge.
- Configuration templates integrate L4 reverse proxy and JWT authentication modules by default, fully capable of acting as an API Gateway.
- Includes Docker/Podman build/compose configurations; easily build custom Caddy modules locally with simple configuration changes.

## Project Structure
```shell
.
├── services                        # Recommended storage for sub-services
├── site                            # Caddy static site
│   └── web
│       └── index.html
├── templates
│   └── Caddyfile.json.template     # Caddy configuration template
├── .env.warp.example               # Template substitution definitions
├── .modules                        # Caddy module definitions
├── compose.yaml                    # Container orchestration config
├── compose.override.yaml           # Container override config - for sub-services
├── Dockerfile                      # Image generation config
├── HEALTHCHECK.md                  # Health check instructions
├── README.md
└── README-cn.md
```
> **Note:** We use JSON configuration directly instead of Caddy's default, more concise Caddyfile.
> This is because the Caddyfile automatically generates redundant configurations when paired with L4 modules. More importantly, the Caddyfile only supports automatic certificate configuration for explicitly declared domain site blocks, whereas our configuration does not require such site blocks at all.

## Usage
1. Install Docker or Podman (recommended), or choose to run natively.
2. Clone this repository:
```shell
git clone https://github.com/Lanrenbang/caddy-services.git
```
> You can also download the [Releases](https://github.com/Lanrenbang/caddy-services/releases) archive.
3. Copy or rename [.env.warp.example](.env.warp.example) to `.env.warp` and modify the necessary content as needed.
4. Refer to the internal comments to modify [compose.yaml](compose.yaml)/[compose.override.yaml](compose.override.yaml) as required.
5. Add the information configured as secrets in the previous step to the keystore:
```shell
echo -n "some secret" | docker secret create <secret_name> - 
echo -n "some secret" | podman secret create <secret_name> - 
```
> Or run `docker/podman secret create <secret_name>` directly and enter the secret when prompted.

> **Note:** `<secret_name>` must match the entries in `.env.warp` and `compose.yaml`.
6. Enter the root directory and start the container service:
```shell
docker compose up -d
podman compose up -d
```

## About Modules
- Check the [.modules](.modules) configuration file. If the modules provided by this project do not meet your expectations, you will need to modify them, which means you cannot use the remote image provided by this project.
- After redefining the required modules, you can easily build a local custom image using the included Dockerfile.
- You can also push the image to your own registry; refer to the project's GitHub Workflow configuration for details.

## Others
- Caddy supports placeholders (variables), but not all fields support them, and support varies across modules. Therefore, this project uses the [envwarp](https://github.com/Lanrenbang/envwarp) tool to perform variable substitution before runtime.
- A reference description for the cache module is provided in the module configuration file, but it is not currently used in this project. If needed, please research and implement it yourself.
- If you do not wish to use containers and prefer to run this project natively, please refer to the [Native Execution Guide](https://github.com/Lanrenbang/xray-services/blob/main/systemd/README.md).
- For container health checks, please refer to the [HEALTHCHECK Guide](HEALTHCHECK.md).

## Related Projects
- [xray-services](https://github.com/Lanrenbang/xray-services)
- [xray-api-bridge](https://github.com/Lanrenbang/xray-api-bridge)

## Credits
- [caddy](https://github.com/caddyserver/caddy)

## Support Me
[![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/bobbynona) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/bobbynona) [![USDT(TRC20)/Tether](https://img.shields.io/badge/Tether-168363?style=for-the-badge&logo=tether&logoColor=white)](https://github.com/Lanrenbang/.github/blob/5b06b0b2d0b8e4ce532c1c37c72115dd98d7d849/custom/USDT-TRC20.md) [![Litecoin](https://img.shields.io/badge/Litecoin-A6A9AA?style=for-the-badge&logo=litecoin&logoColor=white)](https://github.com/Lanrenbang/.github/blob/5b06b0b2d0b8e4ce532c1c37c72115dd98d7d849/custom/Litecoin.md)

## License
This project is distributed under the terms of the `LICENSE` file.


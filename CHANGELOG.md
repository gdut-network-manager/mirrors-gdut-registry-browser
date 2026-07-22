# Changelog

# v2.0.0

> **破坏性变更**: 本版本将应用从 Docker Registry HTTP API V2 浏览器完全重构为 **Harbor Proxy Cache 浏览器**。所有配置、模型、控制器、路由和视图均已重写。

* 从 Docker Registry API 切换到 Harbor 原生 API (`/api/v2.0/`)
* 全局 Basic Auth 认证(Harbor 机器人账户),无 token 流程,无浏览器登录弹窗
* 新增页面层级:项目列表 → 仓库列表 → 标签列表 → 制品详情
* 项目卡片展示配额进度条、存储使用量、仓库数量、创建时间
* 双模式拉取命令带滑块开关(前缀模式 + 域名置换模式,通过 `DOMAIN_MIRROR_MAP` 配置)
* 仓库描述信息 Tab,支持 Markdown 渲染(Commonmarker)
* 制品类型徽章(IMAGE、CHART、WASM、SBOM、CNAI 等)
* Lucide 风格 SVG 图标系统,替换所有 PNG 图标
* 明暗主题切换,支持系统偏好自动检测
* 面包屑导航(带边框圆角 + `|` 分隔符 + 标签名等距字体)
* 底部栏自动贴底(flexbox 布局)
* 新增环境变量: `HARBOR_URL`、`HARBOR_USERNAME`、`HARBOR_PASSWORD`、`PUBLIC_REGISTRY_URL`、`DOMAIN_MIRROR_MAP`、`PAGE_SIZE`
* 移除环境变量: `DOCKER_REGISTRY_URL`、`BASIC_AUTH_USER`、`BASIC_AUTH_PASSWORD`、`TOKEN_AUTH_USER`、`TOKEN_AUTH_PASSWORD`、`SORT_TAGS_BY`、`SORT_TAGS_ORDER`、`ENABLE_COLLAPSE_NAMESPACES`、`ENABLE_DELETE_IMAGES`、`CATALOG_PAGE_SIZE`
* 删除模型: `Resource`、`Current`、`ObtainAuthenticationToken`
* 删除视图: 排序链接、删除标签弹窗、认证错误页
* Helm chart: 新增 `envFromSecrets` 支持 Harbor 凭证管理
* 升级至 Ruby 3.4.1 / Rails 8.1.3
* 新增 `commonmarker` gem(替换 `version_sorter`)

# v1.7.4

* Update to Ruby 3.3.5
* Update to Rails 7.2.1

# v1.7.3

* Update to Ruby 3.3.4
* Update to Rails 7.1.3.4

# v1.7.2

* Allow customizing the catalog page size
* Switch back to default ruby base image (Alpine 3.19 based)
* Update to Ruby 3.2.3
* Update to Rails 7.1.3

# v1.7.1

> **NOTE**:
>
> With this version the way how docker images are pushed is changing slightly:
> Instead of having the `latest` tag being updated on every (potentially) breaking commit merged
> into `master` branch it will be pointing to the last officially published release.
>
> You can switch to the `master` tag if you want to get the newest (unreleased) changes.

* Update to Rails 7.1.2

# v1.7.0

* Update to Rails 7.1.0
* **Breaking change**:
  * The `SECRET_KEY_BASE` option is now mandatory.
    Please create a unique value with `openssl rand -hex 64`

# v1.6.1

* Accept oci manifests and ignore attestations
* Update to Ruby 3.2.2
* Update to Rails 7.0.4.3

# v1.6.0

* Handle case of missing `history` attribute in tag response
* Allow `version` for `SORT_TAGS_BY` environment variable
* Turn off Faraday HTTP request header logging
  * Add environment variable `REGISTRY_LOG_LEVEL` to set log level Faraday uses when writing registry related log events
  * Add environment variable `REGISTRY_LOG_HEADERS` to enable Faraday to log HTTP request headers
* Update to Ruby 3.1.3
* Update to Rails 7.0.4

# v1.5.0

* Handle `null` value in `repositories` property of `/v2/_catalog`
* Add `GET /ping` endpoint for health-checks
* Allow to sort tags
* Add Favicon
* Docker image: Remove `yarn`, Add `libc6-compat`
* Add total manifest size on details page
* Multiarch improvements: show variant & sort
* Also build armv7 images (32bit ARM)
* Fix delete when using token auth
* Update to Ruby 3.1.2
* Update to Rails 7.0.3

# v1.4.0

* Support for multi arch docker images
* Support for oci image format
* Option for collapsed namespaces
* Handle errors on tage delete gracefully
* Support token based auth without hardcoded credentials
* Available as `linux/amd64` and `linux/arm64` on hub.docker.com
* Update to Ruby 3.0.2
* Update to Rails 6.1.4.1

# v1.3.5

* Update to Ruby 2.7.2
* Update to Rails 6.0.3.4
* Gracefully handle token auth issues
* Use ca_file option when obtaining auth token

# v1.3.4

* Fix issue in puma config.

# v1.3.3

* Add new `CA_FILE` option to configure CA for SSL backends
* Update to Rails 6.0.2.2
* Update to Ruby 2.6.6
* Update to Faraday 1.0

# v1.3.2

* Improve token auth support

# v1.3.1

* Update to Rails 6.0.2
* Allow Faraday to follow remote redirects
* Support registries returning json header for blob requests

# v1.3.0

* Update to Ruby 2.6.5 and Rails 6.0.1
* Add `ADDRESS` and `SSL_ADDRESS` options
* Fix an `Illegal instruction` ruby error related to sassc
* Show more details on the tag page (Labels, ENVs, Created Date, ...)

# v1.2.3

* Security fix for nokogiri CVE-2019-5477

# v1.2.2

* Improve warning text for delete tag button

# v1.2.1

* Fix tag delete button for special tag names (like `null`)

# v1.2.0

* Support for standalone SSL

# v1.1.2

* Update to Ruby 2.6.3 and Rails 5.2.3
* Support for links in `/example:latest` format (via redirect)

# v1.1.1

* Update to Ruby 2.6.2 and Rails 5.2.2.1

# v1.1.0

* Support for token based authentication
* Update of used libraries

# v1.0.1

* Reduce size of docker image
* Update of Ruby interpreter to 2.6.0 and some used libraries
* Stop hotlinking of icons from external domain icons8.com

# v1.0.0

* Started versioning the application

Features so far:

* Browse images (by namespace) and their tags
* Delete tags
* Copy & paste of docker pull commands
* Authenticiation with HTTP basic auth or token based authentication against registry

# Changelog

# v2.5.2

* 重构首页布局为 2/3 + 1/3 双区域
  - 左侧 2fr 区域放项目卡片, 内部居中
  - 右侧 1fr 区域放转换器, 撑满整个区域
  - 响应式断点从 1024px 提高到 1200px
  - 放大转换器字号 (输入框/命令文本/工具标签)

# v2.5.1

* 优化镜像名称转换器布局和交互
  - 侧边栏加宽至 420px, 内容字号放大
  - sticky top 设为 88px, 避免顶栏滚动时遮挡卡片
  - 侧边栏 max-height + overflow-y: auto, 内容多时内部滚动
  - 命令文本自动换行 (word-break: break-all), 取消横向滚动
  - 输入提示改为可点击的示例标签, 点击即填入

# v2.5.0

* 新增首页镜像名称转换器
  - 右侧 sticky 卡片, 左侧项目列表正常滚动
  - 支持前缀添加模式和域名置换模式切换
  - 支持 docker / podman / ctr 三种拉取工具
  - 自动补全 `latest` tag, 支持 digest
  - 从 Harbor API 动态构建上游域名映射 (含 Docker Hub 多域名识别)
  - 域名置换模式提醒 Host 文件和 CA 证书配置
  - 每个命令独立复制按钮 + 复制全部按钮
  - 不支持的仓库提示并展示支持列表
  - 移动端 (≤768px) 转换器折叠到项目列表上方

# v2.4.2

* 修复面包屑 SVG 图标与文字垂直对齐问题
  - `.breadcrumb-item a` 添加 `display: inline-flex` + `align-items: center` + `line-height: 1`
* AGENTS.md 新增前端对齐验证规则

# v2.4.1

* 修复 Favicon 子路径部署不显示的问题
  - favicon 文件移入 app/assets/images/, 通过 asset pipeline 提供
  - application.html.erb 改用 favicon_link_tag (自动加 SCRIPT_NAME 前缀)
* 修复错误页面顶栏 Logo 缺失的问题
  - 静态错误页 SVG 图标替换为 GDUT logo 图片
  - JS 动态设置 logo 和 favicon 路径(支持子路径部署)

# v2.4.0

* 重做所有错误页面,采用 Island UI 设计风格
* 静态错误页(public/404, 422, 500): 完整自包含,内联 CSS+JS
  - navbar + 居中 island + footer 布局
  - 警告图标 + 大号错误码 + 描述 + 返回首页按钮
  - 深色/浅色主题切换(localStorage + 系统偏好)
  - 子路径部署根路径推断(/docker/)
* 动态错误页(app/views/errors/): island 风格内容
  - 502 服务不可用: alert 图标
  - 403 无权访问: shield 图标
  - 401 认证失败: shield 图标
* 新增 .error-page CSS 样式到 application.css
* 设计参考: mirrors.gdut.edu.cn 镜像站错误页面

# v2.3.3

* 修复底栏 SVG 图标与文字垂直对齐问题
* 添加 AGENTS.md 版本号提升强制规则

# v2.3.2

* 添加鼠标光斑跟随效果(岛、顶栏、底栏)
* 鼠标移入时显示 radial-gradient 光斑,跟随鼠标位置移动
* 深色主题光斑透明度降低(0.08 vs 0.12)
* 实现参考: mirrors.gdut.edu.cn 镜像站主页

# v2.3.1

* 修复配额进度条正常状态显示为红色的问题(误用主题色)
* 正常状态改为绿色渐变,黄色警告(≥50%),红色危险(≥80%)

# v2.3.0

* 添加对 Harbor 一般项目(非 Proxy Cache)的支持
* 首页混合展示所有项目,代理项目显示绿色上游 registry badge,一般项目显示橙色"本地"badge
* Project 模型添加 `proxy_cache?` 和 `local?` 方法
* 各页面标题动态显示"代理项目"/"本地项目"
* 一般项目标签详情页拉取命令开关灰掉(不支持镜像子域名模式)
* `pull_command_mirror` 对一般项目返回 `nil`

# v2.2.10

* 修复 SBOM 表格点击排序时漏洞列表内容串入的问题
* 根因: 漏洞表格和 SBOM 表格的 `data-sortable-table` 使用了相同的 manifestId,导致 `originalRowOrders` 混合了两个表格的行,`restoreOriginalOrder` 时把漏洞行 append 到 SBOM 表格
* 修复: `data-sortable-table` 加 `vuln-` / `sbom-` 前缀区分,`initTableState` 选择器同步更新

# v2.2.9

* 修复子路径部署(`RAILS_RELATIVE_URL_ROOT=/docker`)下仓库搜索 404 的问题
* 根因: JS 中硬编码 URL `/project/xxx` 缺少 `SCRIPT_NAME` 前缀,生产环境请求到了 `/project/docker?q=core` 而非 `/docker/project/docker?q=core`
* 改为从 `data-search-url` 属性读取 URL(由 Rails route helper `project_path` 生成,自动包含 `SCRIPT_NAME` 前缀)

# v2.2.8

* 修复生产环境仓库搜索返回 404 的问题
* 根因: Turbo Frame 的 `frame.src` 会发送 `Accept: text/vnd.turbo-frame.html` 请求头,生产环境不识别此 MIME 类型返回 404
* 改用普通 `fetch()` + `Accept: text/html`,从响应 HTML 中提取 `#repo-list` 并替换 DOM
* 去掉 `_repo_list` partial 中的 `turbo_frame_tag` 包装,改为普通 div

# v2.2.7

* 仓库搜索改为服务端搜索(Harbor API `q=name=~keyword` 模糊匹配),支持搜索项目下所有仓库而非仅当前页
* 提取 `_repo_list` partial,用 Turbo Frame `src` 更新实现无刷新搜索
* 搜索框 350ms debounce,清空时恢复完整列表
* 搜索框添加搜索图标和聚焦样式

# v2.2.6

* 修复 SBOM 搜索框与摘要统计不在同一行的问题(从 Turbo Frame 内移到外层摘要栏)
* SBOM 摘要栏改为 flex space-between 布局,左侧扫描器/耗时/摘要,右侧搜索框
* SBOM 搜索框宽度从 260px 缩小到 200px 适配窄容器
* 项目页面仓库列表添加搜索过滤框(位于标题和列表之间)

# v2.2.5

* 构建历史改为表格布局(时间/构建命令/注释),与漏洞和 SBOM 表格风格统一
* 按时间由旧到新排序(旧在上,新在下),无分页/搜索/排序按钮

# v2.2.4

* 修复 SBOM 包名列升序状态下点击无响应的 bug(reset 分支重新应用了默认 sorted-asc 标记导致状态不变)
* reset 状态改为清空所有排序标记(不再重新应用默认指示器),3 态循环:降序→升序→无排序→降序

# v2.2.3

* 漏洞列表默认排序改为按严重性从高到低(危急→严重→中等→较低→无评分)
* 修复排序按钮无法切换升序的 bug(turbo:frame-load 导致事件处理器重复绑定)
* 排序改为 3 态循环:降序→升序→恢复默认排序
* 修复严重性排序方向(sev sort-value 反转,数值大=更严重)

# v2.2.2

* 漏洞列表顶部与搜索栏之间添加间距
* CVE 列标题改为"缺陷码"(不止 CVE,还有其他漏洞 ID)
* 漏洞列表默认按 CVSS 评分降序排序,无分数排末尾
* 漏洞/SBOM 表格添加列排序功能:点击列头切换升降序,带三角图标
* 去掉漏洞行的整行背景色,只保留严重性 badge 颜色
* 截图改为暗色模式,与其它截图统一

# v2.2.1

* 性能优化:漏洞列表改为按需 Turbo Frame 异步加载,不再在页面加载时拉取完整漏洞报告(解决 504 超时)
* 漏洞列表改为分页表格(CVE/严重性/CVSS/包/修复版本),每页 20 条,支持严重性筛选和搜索
* SBOM 包列表添加前端分页,每页 20 条
* 修复漏洞分布图表右对齐(添加 `.col-md-4` 网格定义,图表和图例向右对齐)

# v2.2.0

* 新增镜像漏洞扫描结果展示:按严重性分组可折叠列表、CVSS v3 排序、跨分组搜索、双行展开详情
* 新增详情区漏洞分布堆叠条形图(危急/严重/中等/较低/无评分)
* 新增 SBOM 软件物料清单展示:按需 Turbo Frame 加载、SPDX 包列表四列表格、实时搜索
* 镜像详情页重构:构建历史/漏洞扫描/SBOM 子 Tab 切换
* 扫描状态感知:未扫描/进行中/失败/已完成分别展示空状态

# v2.1.0

* 升级至 Ruby 4.0.6
* 升级 `faraday-follow_redirects` 至 0.5.0(支持 Ruby 4.0)

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

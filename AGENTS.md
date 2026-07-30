## Agent skills

### Issue tracker

Issues live in GitLab Issues (self-hosted at gdutnic.com), via `glab` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Versioning

### 版本号提升(强制)

**每次涉及代码改动的提交,必须同时提升版本号。** 不得跳过。

涉及三个文件,版本号必须保持一致:

1. `config/initializers/version.rb` — `Rails.application.config.x.version = "x.y.z"`
2. `helm/Chart.yaml` — `version:` 和 `appVersion:` 两个字段
3. `CHANGELOG.md` — 在文件顶部添加新版本条目,简述改动内容

版本号规则:
- bug 修复、小改动 → patch 版本号 +1(如 `2.3.2` → `2.3.3`)
- 新功能、不兼容改动 → minor 版本号 +1(如 `2.3.2` → `2.4.0`)

在 `git commit` 之前完成版本号提升,与代码改动一起提交。

## Verification

### 前端对齐验证(必读)

每次对前端(CSS/HTML/ERB 模板)进行修改时,**必须**用 Playwright 验证涉及元素的垂直对齐。重点检查:

- SVG 图标与旁边文字的垂直居中(`<a>`、`<button>` 等包含 SVG + 文字的容器)
- 全局 `line-height: 1.6` 会导致文字行框比 SVG 高,需在容器上加 `line-height: 1` + `display: inline-flex` + `align-items: center`
- 验证方法: 用 `browser_evaluate` 检查 SVG 的 `getBoundingClientRect()` center 与容器 center 是否一致

历史教训:
1. 底栏 footer SVG 图标偏下 → `.footer a` 加 `line-height: 1` + `inline-flex`
2. 面包屑 breadcrumb SVG 图标偏下 → `.breadcrumb-item a` 同上

### 生产环境验证(必读)

本地开发环境与生产环境差异较大,仅本地验证通过不代表生产环境没问题。涉及前端、路由、资源、MIME 类型、URL 拼接等改动时,**必须**同时用 Playwright 测试生产环境页面。

- 生产环境地址: `https://mirrors.gdut.edu.cn/docker`
- 生产环境配置了 `RAILS_RELATIVE_URL_ROOT=/docker`(`SCRIPT_NAME=/docker`),所有 URL 必须包含 `/docker` 前缀
- 生产环境是 nginx ingress + Rails production 模式,与本地 Puma dev 模式行为不同
- 不要在 JS 中硬编码 URL 路径,应使用 Rails route helper 生成(会自动包含 `SCRIPT_NAME` 前缀)
- 生产环境需要手动部署,代码推送后不会自动更新。出 Bug 排查时应去生产环境确认实际表现

历史教训:
1. 前端过滤只能搜当前页 → 改用 Harbor API 服务端搜索
2. Turbo Frame 的 `text/vnd.turbo-frame.html` MIME 类型生产环境不识别 → 改用普通 `fetch()` + `Accept: text/html`
3. JS 硬编码 URL `/project/xxx` 缺少 `SCRIPT_NAME` 前缀 → 改用 `data-search-url` 属性由 route helper 生成

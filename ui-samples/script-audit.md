# ABC 网课助手脚本结构与 UI/交互审计

审计对象：`C:\Users\mijiu\Desktop\ABC网课助手\🐮ABC超星学习通｜智慧树网课助手.mod.user.js`

审计时间：2026-10-22

文件事实：

- 大小：515,350 字节
- 行数：13,218
- SHA-256：`2D7AE3A19C035701CDB94449A22A1A91D1BAC9A0B7AFB847D47CC08EC4BFEACC`
- 最后修改：2026-10-21 23:18:06
- 元数据版本：`1.0`（第 4 行）
- 本次审计不修改主脚本；只新增本报告。

审计方式：按模块边界分段通读全文件，并用函数名、组件名、store、路由关键字、存储键、危险 HTML sink 做交叉核对。第三方库区没有逐行业务分析，但已确认其中没有混入本项目业务入口。

---

## 1. 文件结构总览

### 1.1 用户脚本头与依赖

- 第 1–71 行：UserScript 元数据。
- 第 9–12 行：匹配 `chaoxing.com`、`neauce.com`、`zhihuishu.com`、`edu.cn`。
- 第 13–29 行：外部依赖 Vue 3.4.31、Pinia 2.1.7、Day.js、DOMPurify、Ant Design Vue 4.2.6、md5、RxJS、marked。
- 第 30–31 行：字体解密查表资源 `ttf` / `ttf2`。
- 第 60–65 行：GM 存储、跨域请求、`unsafeWindow` 权限。
- 第 66 行：`document-start` 注入。

### 1.2 模块边界

| 行号区段 | 内容 | 性质 |
|---|---|---|
| 73 | 全量 UI CSS 字符串 | 本项目 UI 样式 |
| 75–80 | 主 IIFE 与打包辅助函数 | 业务入口 |
| 81–1348 | Ant Design Vue 图标与样式注入辅助代码 | 打包库 |
| 1349–1438 | 脚本信息、时间工具、log store、`UserLog` | 业务 |
| 1439–1683 | 设置默认值、深合并、`ScriptHome` | 业务 |
| 1684–1862 | question store、`AutoAnswer` | 业务 |
| 1863–2046 | `UserConfig` | 业务 |
| 2047–2464 | 答题记录、API/模型调用、在线搜索 | 业务 |
| 2465–2660 | `OnlineSearch`、AI 组件模板头部 | 业务 |
| 2661–2967 | `AiHome`、`AnswerRecord`、message store | 业务 |
| 2968–3091 | 基础信息/余量请求、划词搜题 | 业务 |
| 3092–6198 | Typr 字体解析器与 Font 包装 | 打包库 |
| 6199–6260 | 超星字体解密 | 业务 |
| 6261–7279 | RxJS 运行时与操作符 | 打包库 |
| 7280–12462 | 答题处理器、超星/智慧树自动流程、路由表 | 业务自动化 |
| 12464–13132 | 面板内容层、悬浮壳、迷你态 | 业务 UI |
| 13133–13223 | 页面级启动、Shadow DOM、Vue 挂载、错误 Hook | 业务入口 |

### 1.3 路由方式

没有 Vue Router。入口读取当前 URL，在 `platformConfigs` 中按域名识别平台，再用 `routes.match` 数组做 `url.includes(keyword)` 匹配：

- 平台表：12515–12550。
- 超星路由：9296–9316。
- 智慧树路由：12432–12462。
- 匹配执行：12596–12638。

路由项可以附带：

- `tab`：进入后切换的标签页 key。
- `logic`：启动对应自动化流程。
- `log`：写入一条初始日志。

默认路由会显示面板，但不启动学习/答题逻辑。

---

## 2. UI 架构

### 2.1 挂载方式

- 脚本在 `document.readyState === "complete"` 后创建 `#abc-helper-root`。
- 根节点附加开放 Shadow DOM。
- Vue app 挂载到 `#abc-helper-app`。
- 使用 `a-config-provider` 和 `a-style-provider`，后者把 AntD 样式放入 Shadow DOM。
- 页面 `<head>` 后续新增的 `<style>` 会被克隆进 Shadow DOM，保证动态插入的组件样式可见。

关键位置：

- Shadow 创建：13193–13209。
- Vue 挂载：13213–13218。
- AntD Provider：13108–13131。
- 样式克隆：13156–13183。
- 完整 CSS：第 73 行。

### 2.2 组件层级

```text
App
└─ 悬浮壳 index (_sfc_main$1)
   ├─ 迷你态按钮 (48×48)
   ├─ 消息 alerts
   └─ main-box
      ├─ box-header
      │  ├─ logo + ABC-版本
      │  ├─ 后台下拉
      │  └─ 收起按钮
      └─ 内容层 index (_sfc_main$2)
         ├─ a-tabs（只负责导航）
         └─ 动态组件
            ├─ ScriptHome
            ├─ UserLog
            ├─ AutoAnswer
            ├─ OnlineSearch
            ├─ AiHome（仅超星）
            ├─ UserConfig
            └─ AnswerRecord（隐藏 tab）
```

### 2.3 导航与可见标签

`contentMap` 定义在 12515–12551。

超星平台（`showAi: true`）：

| key | 标签 | 组件 |
|---|---|---|
| `0` | 🏠 首页 | `ScriptHome` |
| `1` | 📄 日志 | `UserLog` |
| `2` | 🖥️ 答题 | `AutoAnswer` |
| `3` | 🔎 在线搜题 | `OnlineSearch` |
| `4` | 🤖 AI | `AiHome` |
| `5` | 👤 设置 | `UserConfig` |
| `record` | 不显示 | `AnswerRecord` |

智慧树平台（`showAi: false`）：

| key | 标签 | 组件 |
|---|---|---|
| `0` | 🏠 首页 | `ScriptHome` |
| `1` | 📄 日志 | `UserLog` |
| `2` | 🖥️ 答题 | `AutoAnswer` |
| `3` | 🔎 在线搜题 | `OnlineSearch` |
| `4` | 👤 设置 | `UserConfig` |
| `record` | 不显示 | `AnswerRecord` |

结论：并不存在固定“六个 tab”的统一结构。超星是 6 个可见 tab，智慧树是 5 个；设置页 key 会随 AI 是否存在而从 `5` 变为 `4`。

### 2.4 “后台”入口

- 顶部“后台”是 hover 下拉，不是普通 tab。
- 菜单项：`日志输出`、`答题记录`。
- 选择后分别写入 `setting.tabIndex = "1"` 或 `"record"`。
- `record` 是隐藏 tab，不显示在 AntD tab 导航中，但可被动态组件渲染。

位置：12765–12777、13052–13087。

### 2.5 主态/迷你态

- 主态位置使用 `setting.position.right/top`。
- 迷你态位置使用 `setting.position.miniRight/miniBottom`。
- 迷你按钮 48×48，拖动延迟 180ms。
- 单击迷你按钮展开；拖动超过阈值只移动，不展开。
- 展开后使用主态位置，不自动从迷你按钮位置展开。
- `isMini` 是组件内 `ref(false)`，刷新页面后始终回到展开态；只有位置持久化。

位置：12751–12887、12995–13013。

### 2.6 布局与视觉事实

- 主面板白底、8px 圆角、阴影、`position: fixed`、`z-index: 99999`。
- 字体主体使用 `Menlo / Monaco / Consolas / Courier New` 等宽字体。
- 内容宽度：`tab-content` 500–520px；设置区 470–500px；AI 区 500px。
- 头部高度 30px。
- `a-tabs-nav-operations` 被全局隐藏，超宽时不会出现 AntD 的“更多”导航按钮。
- 日志区固定 300px 高，深色背景。
- AI 消息区固定 500px 高。
- 答题详情区最大 200px 高。
- 通过 `a-tabs` 只渲染导航项，实际内容由单个 `currentContent` 动态组件渲染；切换 tab 会卸载/重建局部组件。

样式位置：第 73 行、12720–12742。

---

## 3. 状态与 Stores

### 3.1 `log` store

- 位置：1378–1393。
- 状态：`logList: []`。
- 每项：`{ text, time, type, tabIndex }`。
- 不持久化；刷新后清空。
- 无条数上限、无清空 action。
- `tabIndex` 字段当前没有消费者。
- 日志文本使用 `innerHTML` 渲染（1426）。

### 3.2 `setting` store

- 位置：1453–1615。
- 启动时从 GM key `setting` 读取 JSON。
- 使用 `deepMerge(defaultSetting, localStore)`。
- 合并后强制 `version = 当前脚本版本`。
- 合并后强制 `config.basicConfig.answerMode.value = "ai"`（1607）。
- 外层 store watcher 在 12779–12785 深度监听并写回 `GM_setValue("setting", JSON.stringify(newVal))`。

默认值：

```js
{
  tabIndex: "0",
  answering: true,
  version: <GM_info.version>,
  position: {
    right: "0px",
    top: <innerHeight * 20%>,
    miniRight: undefined,
    miniBottom: undefined
  },
  shopLink: "",
  latestVersion: "",
  chatWebUrl: "",
  config: {
    cxConfig: {
      showCustomEditor: true,
      faceRecognitionNotify: true
    },
    basicConfig: {
      modelApiUrl: "https://api.deepseek.com/v1/chat/completions",
      modelApiKey: "",
      modelName: "deepseek-chat",
      modelApiSessionId: "",
      answerOnly: false,
      answerMode: "ai",
      videoPlayrate: 2,
      reqIntervalTime: 2,
      accuracy: 80,
      autoSubmit: true,
      autoChangeChapter: true,
      skipFinishedChapter: true,
      autoAnswer: true,
      autoRefresh: true
    },
    examConfig: {
      autoSubmit: false
    },
    searchConfig: {
      searchBySelectedText: false
    }
  },
  userInfo: {
    remainCount: 0
  }
}
```

注意：`deepMerge` 只遍历默认对象的 key（1439–1452），所以旧版本遗留但默认结构里不存在的 key 会被丢掉。

### 3.3 `questionStore`

- 位置：1684–1700。
- 状态：
  - `questionList`
  - `currentQuestionIndex`
  - `accuracy`
  - `searchText`
  - `fuzzySearchResult`
- 全部为内存态，刷新丢失。

### 3.4 `messageStore`

- 位置：2968–2984。
- 状态：`messageList`。
- 用于顶部 `a-alert` 警告。
- 不持久化。
- `clearMessage()` 已定义但没有调用点。
- 弹窗关闭只影响局部 DOM，不会从 store 移除消息。

### 3.5 `answerRecord` store

- 位置：2073–2109。
- GM key：`answerRecords`。
- 最大 200 条，新记录插入头部。
- 记录结构：

```js
{
  cacheKey, token, title, requestTime, timestamp,
  answer, type, optionsText, workType, refer, source
}
```

- `source` 默认 `accurate`，AI 路径写 `ai`。
- 记录页读取的是 `record.model`，但写入时没有写 `model` 字段，实际会一直显示“未配置”。这是现有数据/UI 契约不一致。

### 3.6 其他持久化/全局状态

GM 存储：

- `setting`
- `answerRecords`
- `modelApiSessionId`

sessionStorage：

- `abc-answer-only-q:<chapterKey>`
- `abc-answer-only-jump`
- `abc-opened-exam-iframe:<url>`
- `abc-zhs-wisdom-study-reload-count`

页面全局标记：

- `unsafeWindow.__abcHelperLoaded`
- `unsafeWindow.__ABC_ZHS_ANSWER_SHEET__`
- `unsafeWindow.__ABC_ZHS_ANSWER_SHEET_HOOKED__`
- `XMLHttpRequest.callbacks`

---

## 4. UI 页面细节

### 4.1 首页

位置：1627–1682。

- 提示区。
- 版本与最新版本对比。
- 浏览器建议。
- 服务器异常提示。
- 使用教程。
- `chatWebUrl` 通过 `innerHTML` 注入。

### 4.2 日志

位置：1397–1438。

- 深色控制台。
- 自动滚到底部。
- 日志/警告两类。
- 文本 `innerHTML` 渲染。
- 空态显示“等待用户进入正确页面..”。

### 4.3 答题

位置：1723–1862。

- 暂停/开始答题。
- “只答题（跳过视频）”快捷开关。
- 进度 `current / total`。
- 准确率。
- 题目状态图例。
- 题目编号列表。
- 当前题详情。

状态码映射：

- `1` → 题库答案
- `2` → AI 答案
- `-1` → 默认
- 其他/异常 → warning

### 4.4 在线搜题

位置：2465–2648。

- 划词搜题开关。
- 手动输入题目。
- 调用 `fetchFuzzySearch()`。
- 结果来自用户配置的模型 API，不是独立题库接口。
- 结果标题、答案通过 `innerHTML` 渲染。

### 4.5 AI 对话

位置：2674–2835。

- 本地消息列表。
- 非流式 `GM_xmlhttpRequest`。
- Markdown 由 `marked` 渲染后写入 `innerHTML`。
- 切换 tab 后组件卸载，聊天历史丢失。
- 没有真正使用 `AbortController` 终止请求。

### 4.6 设置

位置：1877–2046。

设置分类：

- 基本设置：14 项
- 考试设置：1 项
- 超星设置：2 项

`searchConfig` 不在本页渲染；划词开关只在“在线搜题”页。

设置组件副作用：

- 监听 `basicConfig.token`，变化后刷新页面。
- 监听 `videoPlayrate`，变化后刷新页面。
- 监听 `autoRefresh`，重新调用自动刷新计时器。

但当前默认配置里没有 `token`、`serverNode` 字段；相关代码属于残留/未清理路径。

### 4.7 答题记录

位置：2856–2967。

- 按今天、昨天、近一周、近一月筛选。
- 最多 200 条。
- 显示模型、题目、答案、时间。
- 模型列当前没有正确数据来源。

---

## 5. 设置项与默认值

### 5.1 基本设置（14）

| key | 文案 | 默认 |
|---|---|---|
| `modelApiUrl` | 模型 API 地址 | `https://api.deepseek.com/v1/chat/completions` |
| `modelApiKey` | 模型 API 密钥 | 空 |
| `modelName` | 模型名称 | `deepseek-chat` |
| `modelApiSessionId` | 会话 ID | 空，运行时自动生成并持久化 |
| `answerOnly` | 只答题（跳过视频） | `false` |
| `answerMode` | 答题模式 | `ai`，仅“纯AI” |
| `videoPlayrate` | 视频倍速 | `2`，可选 1 / 1.5 / 2 |
| `reqIntervalTime` | 搜题间隔（秒） | `2`，范围 1–3 |
| `accuracy` | 正确率 | `80` |
| `autoSubmit` | 章节、作业自动提交 | `true` |
| `autoChangeChapter` | 自动切换章节 | `true` |
| `skipFinishedChapter` | 跳过已完成章节 | `true` |
| `autoAnswer` | 自动答题 | `true` |
| `autoRefresh` | 定时刷新 | `true`，实际 30 分钟 |

### 5.2 考试设置（1）

| key | 文案 | 默认 |
|---|---|---|
| `autoSubmit` | 自动交卷 | `false` |

### 5.3 超星设置（2）

| key | 文案 | 默认 |
|---|---|---|
| `showCustomEditor` | 编辑时显示自定义编辑框 | `true` |
| `faceRecognitionNotify` | 出现人脸识别时通知我 | `true` |

### 5.4 搜索设置（1）

| key | 文案 | 默认 |
|---|---|---|
| `searchBySelectedText` | 划词搜题 | `false` |

---

## 6. 交互与自动化流程

### 6.1 启动流程

1. `document-start` 时先写入 CSS 字符串。
2. 等待 DOM complete。
3. 仅顶层窗口创建 Shadow DOM 和 Vue app。
4. 面板内容层根据域名选择平台配置。
5. `chooseLogicByUrl()` 做 URL 关键字匹配。
6. 请求 `/info/baseInfo` 获取最新版本和商店链接。
7. 若匹配到路由，写入默认 tab、写日志、调用 `logic()`。
8. 启动划词监听和自动刷新计时器。
9. 面板通过 `customEvent` 控制显示。

### 6.2 超星主流程

入口：8258–9166。

任务点识别：

- 作业 iframe：`api/work`
- 视频：src 含 `video`
- 音频：src 含 `audio`
- 文档：`modules/ppt|doc|pptx|docx|pdf`
- 电子书：`modules/innerbook`

处理策略：

- 视频/音频：静音、倍速、暂停恢复 watchdog、视频弹题自动跳过。
- 文档：`finishJob()` 或翻页。
- 电子书：解析 `timing` 参数，等待计时，或调用平台翻页。
- 作业：解密字体、解析题目、答题、按正确率决定提交/暂存。
- 任务点确认：监听 `/ananas/job` 上报响应并等待 `ans-job-finished`。

章节切换：

- 优先找“确定未完成”的章节。
- 读取不到状态时不主动跳，避免空跳。
- 到最后一章时给出手动提示。
- 同一章重复进入达到阈值会停止自动跳转。

### 6.3 “当前章节还有任务点未完成”弹窗

处理函数：8530–8568。

当前行为：

- 在顶层文档和嵌套 iframe 中查找可见弹窗/文本。
- 找文本为“去学习”的按钮。
- 若处于“只答题”模式，先临时关闭该模式。
- 点击“去学习”，继续完成本章任务。
- 任务点完成后再恢复“只答题”模式。

仍存在手动兜底：

- 8758–8767：同一章节 90 秒内再次出现，且未能处理弹窗时，记录“已停止自动跳转，请手动切换章节”。
- 8437–8452：同章重复进入 3 次后判定为卡住。
- 8622–8630：最终仍会停止并提示可能存在需要手动完成的章节测试。

这与截图中出现的“同一章节反复出现……请手动切换章节”完全对应。当前脚本并未彻底消除这一中断路径。

### 6.4 答题流程

通用处理器：7280–8005。

- 题型标准化：单选、多选、判断、填空、简答、名词解释、论述、计算、连线、完型、阅读。
- 解析 DOM，提取题干、选项、题型。
- 通过用户模型 API 获取答案。
- 按题型填入 radio、checkbox、textarea、UEditor、连线控件、组合选项。

当前实际答题来源：

- `answerMode` 加载时强制为 `ai`。
- 因此 `getAccurateAnswer()` / 题库路径虽保留，但默认不可达。
- UI 中的“题库答案”图例和答题记录来源保留着旧语义。

### 6.5 在线搜题

`fetchFuzzySearch()` 调用用户模型，要求返回包含题目、类型、选项、答案的 JSON，再包装成一条“搜索结果”。

因此：

- 这是模型搜题，不是第三方题库查询。
- 搜索与 AI 答题共用同一模型配置。

### 6.6 智慧树流程

存在多套独立适配器：

- 旧视频页：9623–9930
- `learnPage`：9931–10235
- `fusioncourseh5` AI 智慧课：10236–10649
- 新形态课程：10650–11029
- 共享课：11030–11236
- 新形态作业/考试：11337–11845
- 校内课/教学空间：11846–12074
- 新智慧学习页：12075–12431

共同特征：

- 按 URL 选择具体适配器。
- 自己查找资源列表、视频、PPT、电子书、章节。
- 多数倍速上限被代码限制为 1.5x，即使设置页可选 2x。
- 多数流程在 `answerOnly` 为真时直接退出学习逻辑。
- 弹窗、验证码、学习习惯提示多处仍要求手动处理。

### 6.7 暂停/恢复

- 答题页按钮切换 `setting.answering`，同时同步 `autoAnswer`。
- 自动化读取的是 `autoAnswer`（或 `answerOnly`），不是统一的暂停状态机。
- 设置页直接修改 `autoAnswer` 时，不会同步 `answering`，两个状态可能不一致。
- 超星检测到“只答题”被平台阻止时，会临时改 `answerOnly=false`，完成本章后恢复。

### 6.8 自动刷新

- 设置项触发 `autoRefreshPage()`。
- `true` 时创建 30 分钟 interval。
- `false` 时只清除当前 `refreshTimer`。
- 多次从关到开不会先清理旧 interval，存在计时器叠加风险。

### 6.9 错误与人工兜底

现有设计大量依赖字符串日志，没有统一的任务状态机。典型人工兜底文案：

- 未识别题型
- 未找到下一章节
- 文档任务点缺少完成入口
- 任务点未确认完成
- 未找到交卷按钮
- 未找到整卷预览按钮
- 验证码超时
- 视频加载失败多次
- 学习习惯弹窗需手动处理

这些是 UI 重构时必须保留或重新建模的核心状态，不应被简单的“成功/失败” toast 覆盖。

---

## 7. 与当前讨论相关的关键事实

### 7.1 迷你态

- 迷你态不是独立页面，是同一面板的条件分支。
- 只有位置持久化，展开/收起状态不持久化。
- 点击迷你按钮展开，拖动移动。
- 展开回到上一次主态位置，不继承迷你按钮位置。

### 7.2 状态展示

- 进度分散在 `questionStore`、`setting`、`logList`、`messageList` 和自动化局部变量中。
- 没有全局“当前任务、当前章节、当前步骤、暂停原因、下一步动作”的单一状态对象。
- 答题页只展示题目进度和准确率，不展示章节任务点状态。

### 7.3 日志

- 日志是独立 tab，同时可从“后台”下拉进入。
- 不持久化、不封顶、无清空入口。
- 日志内容允许 HTML，现有调用会写 `<span class='module'>`。

### 7.4 答题与来源优先级

- 当前运行时是纯 AI。
- 题库 API、余量、节点选择等旧能力仍有代码痕迹，但主路径被 `answerMode="ai"` 锁死。
- “在线搜题”也是模型调用。

### 7.5 异常处理

- 大量异常只写日志后返回，不会自动重试或恢复。
- 超星任务点有重复确认、90 秒章节跳转保护、3 次重复进入保护。
- 这些保护对稳定性有价值，但会表现为用户看到的“停止，请手动处理”。

---

## 8. 重构风险点与不可破坏的契约

### 8.1 存储契约

不要随意改名：

- `setting`
- `answerRecords`
- `modelApiSessionId`
- `abc-answer-only-q:<chapterKey>`
- `abc-answer-only-jump`
- `abc-zhs-wisdom-study-reload-count`

`setting` 的嵌套路径被自动化直接读取，尤其是：

- `config.basicConfig.autoAnswer`
- `config.basicConfig.answerOnly`
- `config.basicConfig.autoChangeChapter`
- `config.basicConfig.skipFinishedChapter`
- `config.basicConfig.autoSubmit`
- `config.basicConfig.accuracy`
- `config.basicConfig.reqIntervalTime`
- `config.basicConfig.videoPlayrate`
- `config.basicConfig.modelApiUrl`
- `config.basicConfig.modelApiKey`
- `config.basicConfig.modelName`
- `config.examConfig.autoSubmit`
- `config.searchConfig.searchBySelectedText`

### 8.2 路由/tab 契约

- tab key 不是纯 UI 编号，自动化流程会主动写 `setting.tabIndex = "1"` / `"2"`。
- 智慧树没有 AI tab，设置 key 从 `5` 变成 `4`。
- `record` 是隐藏 pseudo-tab，必须能被 `tabIndex = "record"` 激活。
- 不支持当前 key 时回落到首页。

重构导航时必须保留：

- `setting.tabIndex` 的字符串类型。
- key 到组件的映射。
- 不同平台下 AI/设置 key 的差异。
- 自动化对 `"1"` 和 `"2"` 的硬编码跳转。

### 8.3 DOM/Shadow DOM 契约

必须保留或同步修改：

- `#abc-helper-root`
- `#abc-helper-app`
- `unsafeWindow.__abcHelperLoaded`
- AntD 的 `getPopupContainer` 指向 Shadow DOM 内 app 节点
- Shadow DOM 样式克隆和 `a-style-provider`

否则 AntD 下拉、消息、提示框会落回页面 body，出现定位或样式问题。

### 8.4 CSS 契约

完整 UI CSS 是一个压缩字符串，位于第 73 行。组件依赖大量现有 class：

`main-wrap`、`main-box`、`box-header`、`box-content`、`tab-content`、`config-wrap`、`answer-wrap`、`log-wrap`、`record-wrap`、`mini-logo-button` 等。

如果重构组件结构但不替换整套 CSS，会出现样式断层。建议后续整体替换 CSS 字符串，而不是局部叠加。

### 8.5 状态契约

- 主面板切换 tab 会卸载当前动态组件；AI 聊天、搜索局部状态会丢。
- 如果新 UI 要保留聊天历史，需要把消息提升到 store。
- `answering` 与 `autoAnswer` 目前可能失配；重构时应明确单一状态源。
- `autoRefresh` 需要防止重复 interval。

### 8.6 自动化 DOM 选择器契约

脚本深度依赖平台 DOM：

- 超星：`.posCatalog_active`、`#prev_tab .prev_ul li`、`#prevNextFocusNext`、`.jb_btn_92.nextChapter`、`.ans-job-finished`、`#curChapterId`、`#curCourseId`、`#curClazzId`。
- 超星题目：`.TiMu`、`.questionLi`、`.answerBg`、`.answer_p`、`.filling_answer`、`.reading_answer`。
- 智慧树：`.resources-list .resources-item`、`.preview-section`、`.chapter-content`、`.el-tree-node`、`.ai-test-question-wrapper`、`.masterylevel-body`。

这些是功能核心，不属于 UI 组件层；重构时不要顺手改自动化选择器。

### 8.7 安全/渲染风险

现有多处 `innerHTML`：

- 日志文本：1426
- 首页 `chatWebUrl`：1664
- 答题题目/答案：1844、1850
- 在线搜索错误/标题/答案：2614、2623、2636
- AI Markdown：2805
- 字体解密：6244

其中模型输出、远程错误和搜索结果显示到 Shadow DOM 时没有统一净化。UI 重构不应把这条风险原样复制。

### 8.8 现存 bug / 残留

- 答题记录写 `token`，UI 读 `record.model`，模型列永远“未配置”。
- `serverNode`、`token` 被引用但默认配置和设置页都没有字段。
- 首页仍提示“更换节点”，实际节点选择路径不可用。
- `getTokenInfo()`、`messageStore.clearMessage()`、`selectedIndex`、`shopLink` 等存在无消费者或低使用实现。
- `answerMode` 被强制为 `ai`，旧题库/准确率路径不可达。
- `autoRefresh` 重复开启可能叠加 interval。

---

## 9. 现有假设与最新脚本的差异

| 现有假设 | 最新脚本事实 |
|---|---|
| 固定六个 tab | 超星 6 个，智慧树 5 个；AI 是条件 tab |
| 设置页固定 key `5` | 有 AI 时是 `5`，无 AI 时是 `4` |
| 日志只能在后台下拉打开 | 日志本身也是可见 tab；后台下拉是第二条入口 |
| 答题记录是普通 tab | 它是隐藏 `record` pseudo-tab，只能从后台下拉进入 |
| 在线搜题查询题库 | 当前调用用户模型，本质是 AI 搜题 |
| 自动答题有题库 + AI 双来源 | 当前启动时强制纯 AI，题库路径为残留 |
| 迷你态会记住展开/收起 | 只记住位置，刷新后默认展开 |
| 迷你态与主态共享位置 | 两套位置字段，展开不继承迷你位置 |
| “只答题”模式始终跳过视频 | 平台阻止跳章时会临时关闭，先完成本章任务 |
| 出错一定会自动恢复 | 很多路径只写 warning 后停止，等待用户手动处理 |
| 答题记录的模型列有值 | 写入 schema 不包含 `model`，UI 显示逻辑不匹配 |
| 设置页包含所有设置 | 划词搜题只在在线搜题页；节点/Token 字段缺失 |

---

## 10. 审计结论

这个脚本不是“一个 Vue 页面 + 几个按钮”，而是：

1. 一个 Shadow DOM 内的 Vue/AntD 悬浮应用；
2. 一套以字符串 tab key 驱动的动态内容层；
3. 五个 Pinia store 和多个 GM/sessionStorage 持久化键；
4. 两套平台路由表；
5. 十几套平台专属 DOM 自动化流程；
6. 大量平台 DOM 选择器、全局 hook 和人工兜底路径。

UI/交互重构可以替换视觉层和导航壳，但不能把自动化逻辑、tab key、存储结构和平台选择器当成“页面样式”一起重写。

最需要先处理的结构问题是：

- 统一任务/暂停/异常状态模型；
- 明确主态/迷你态状态与位置行为；
- 保持动态 tab key 与平台差异；
- 保留隐藏 `record` 入口；
- 保持 `setting` 嵌套结构和自动化读取路径；
- 对日志、AI Markdown、搜索结果的 `innerHTML` 做统一处理。


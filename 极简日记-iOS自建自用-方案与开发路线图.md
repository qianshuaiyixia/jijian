# 极简日记（iOS 自建自用版）— 方案选型与开发上线步骤

> 基于《极简日记APP（一期基础版）PRD》审阅修订
> 已定决策：**仅 iOS ｜ Flutter ｜ 一天可多篇 ｜ 开发机为 Windows（无 Mac）**
> 最后更新：2026-10-12

---

## 〇、最重要的前提：这份 App 是给你自己用的

原 PRD 是按"要交付给别人的商业产品"写的——双端适配、上线验收六条、 )}
权限说明与兼容矩阵，这些对你全部不成立。自用产品的最优解完全不同：

| 商业产品思维 | 自用产品思维 |
| --- | --- |
| 最大风险是"功能不全" | 最大风险是"**你根本不会坚持用**" |
| 验收标准：功能清单打勾 | 验收标准：**连续记录 30 天** |
| 覆盖所有用户的场景 | 只覆盖你自己的习惯路径 |
| 权限/合规/兼容矩阵 | 能装上去、不丢数据就够了 |

**因此一期真正的成功指标只有一条：从解锁到写完保存，≤3 次点击、≤10 秒，并且你能连续用一个月的每天打开它。**

---

## 一、对原 PRD 的裁剪建议

### 1.1 建议砍掉（ROI 极低）

| 条目 | 砍掉理由 | 替代方案 |
| --- | --- | --- |
| **PDF 导出** | 中文+图文混排 PDF 是隐藏深坑（字体嵌入、分页、图片缩放），占一期 20%+ 工作量 | 导出 Markdown / TXT，图片存同级 `assets/`；真要 PDF 就在 iPhone 上用系统"打印→存储为 PDF"，排版比自己写的好 |
| **3-5 款国风信纸** | 视觉成本集中在后期打磨，自用先看内容 | 一期只做 1 款（米白/宣纸底纹），看腻了再加 |
| **4-6 位数字密码** | 已有 Face ID 时边际价值低；且 PRD **未定义"忘记密码怎么办"**——自用 App 最容易把自己锁死 | 只做 Face ID + 后台自动锁定。不设备用密码，避免自锁风险 |
| **定期本地自动备份** | 备份在 App 沙箱内 = 卸载照样全没，等于没备份 | 改为「导出到系统文件 App / iCloud」，手动但真实有效 |
| **双端 Android 适配** | 已决策砍掉 | — |
| **自研数据加密** | 见下方 §1.3 | 依赖 iOS 沙箱 + 设备加密 + Face ID |

### 1.2 必须补充（PRD 现有漏洞）

1. **多篇 vs 单篇的组织规则**（已决策：一天可多篇）
   - 时间轴：同一天的多篇按写入时间倒序，同一天只显示一个日期分隔条（视觉上聚合）
   - 日历页：有记录的日期打点；点击进入当日列表
   - 补写：允许选择任意历史日期，该篇归入所选日期而非今天

2. **数据模型章节缺失**（PRD 的核心缺项）→ 见 §3.2

3. **图片存储与导出规则**
   - 存储：`Documents/images/<yyyyMMddHHmmss>_<n>.jpg`，库里只存相对文件名
   - 删除日记 → 级联删除图片文件；编辑时删图 → 先移除记录，App 退出时清理孤儿文件
   - 导出：单篇 → Markdown + 图片；全部 → 一个 zip（Markdown 集合 + assets）

4. **导入/迁移入口**
   - 支持批量导入 TXT / Markdown（按文件名或首行 `# YYYY-MM-DD` 识别日期）
   - 这是你的数据主权底线：哪天换了方案，记录能带走

5. **导出路径必须用 iOS 原生方式**
   - 使用系统分享面板（UIActivityViewController / `share_plus`），由你自己选择存到"文件"App、iCloud Drive、微信等
   - **不要**写死路径——iOS 沙箱下你也够不到别人的目录

### 1.3 关于"隐私加密"的建议：**不要自己实现加密**

PRD 写了"基础隐私加密保护"，但在 iOS 上这是负收益：

- iPhone 已有硬件级数据保护（设备加密），锁屏未解锁时沙箱数据无法读取
- App 内数据本来就躺在自己的沙箱里，其他 App 无法访问
- 自己实现 AES 意味着：密钥管理、性能损耗、一旦密钥丢失数据永久不可恢复

**结论：隐私靠「Face ID 解锁 + 后台自动锁定 + iOS 沙箱」三件套即可，一期不做自研加密。** 把"加密"这一项的预算挪到"可靠的导出能力"上，后者才是真正保命的。

---

## 二、技术方案

### 2.1 核心链路（针对「Windows 开发 + iOS 安装」）

```
Windows 写代码 ──git push──> GitHub ──> Codemagic(云 macOS)
                                            │ 签名 + 打包
                                            ▼
                                    App Store Connect
                                            │ TestFlight
                                            ▼
                                      你的 iPhone
```

**本地调试用 Flutter Windows 桌面端**（`flutter run -d windows`）：
真窗口、真字体渲染、真文件读写，比 Chrome 更接近原生体验，热重载最快。**不用任何模拟器。**

iOS 独有差异（Face ID、相册、分享面板）通过 Platform Channel 抽象一层，Windows 侧提供 stub 实现，不影响 90% 的 UI/逻辑开发。

### 2.2 为什么是 Codemagic

- Flutter 官方推荐，自动识别 Flutter 项目
- **免费额度 500 分钟/月 macOS M2**，个人自用绰绰有余（一次 iOS 构建约 5–10 分钟）
- 内置 Apple 证书管理与 App Store Connect 发布集成

> 备选：GitHub Actions 的 macOS runner（macOS 机型按 10 倍分钟数计费），仓库需公开才能免费用 macOS runner。自用仓库不想公开就用 Codemagic。

### 2.3 依赖选型

| 用途 | 包 | 说明 |
| --- | --- | --- |
| 数据库 | **drift** | ⚠️ **关键**：`sqflite` 在 Windows 桌面端跑不了（需 ffi + sqlite3.dll）。drift 天然支持 iOS/Android/Windows/macOS 统一 API，本地调试和真机完全一致 |
| 状态管理 | flutter_riverpod | 轻量，够用 |
| 文件路径 | path_provider | Documents 目录 |
| 生物识别 | local_auth | Face ID |
| 密钥/口令 | flutter_secure_storage | Keychain |
| 图片选择 | image_picker | 相册多选 + 拍照 |
| 导出分享 | share_plus | 系统分享面板 |
| 打包 zip | archive | 全部导出 |
| 日期格式化 | intl | 中文星期、农历（可选） |
| 路由 | go_router | 页面导航 |

### 2.4 关于全文检索的建议

**一期直接用 SQL `LIKE '%关键词%'`**，不要上 FTS5。

理由：你的实际数据量（几千篇，单篇千字级）下 LIKE 毫秒级完成，零复杂度。

若将来确实到几万篇：FTS5 默认 `unicode61` 分词器会把**连续汉字视为一个整体 token**，中文检索会失效。届时应用 `tokenize = 'trigram'`（SQLite 3.34+），并注意 trigram 要求查询词 ≥3 字符，两字词回退到 LIKE。——这是后话，现在不要为此多花一分钟。

---

## 三、数据模型

### 3.1 ER 说明

```
diary (1) ────< (N) diary_image
```

### 3.2 表结构（drift）

**表 `diaries`**

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | INTEGER PK AUTOINCREMENT | |
| date | TEXT `YYYY-MM-DD` | 所属日期（支持补写），**建索引** |
| content | TEXT | 正文 |
| created_at | INTEGER (ms epoch) | 创建时间，排序用 |
| updated_at | INTEGER (ms epoch) | 更新时间 |
| word_count | INTEGER | 写入时计算并冗余，避免列表页统计卡顿 |
| paper | TEXT | 信纸标识，默认 `rice-paper` |
| font_scale | TEXT | `small`/`medium`/`large` |
| deleted_at | INTEGER NULL | 软删除，回收站预留（默认为 NULL） |

**表 `diary_images`**

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | INTEGER PK | |
| diary_id | INTEGER FK → diaries.id ON DELETE CASCADE | |
| file_name | TEXT | 相对路径，如 `images/20261012_093000_1.jpg` |
| sort_order | INTEGER | 展示顺序 |
| width / height | INTEGER | 用于列表页占位，避免布局跳动 |
| created_at | INTEGER | |

**索引**：`diaries(date)`、`diaries(created_at DESC)`、`diary_images(diary_id)`

### 3.3 关键业务规则

- 空白内容（纯空格/换行/空图片）**不允许保存**
- 退出编辑页（返回/切后台/锁屏）自动保存草稿；无内容则丢弃，不入库
- 删除日记：二次确认 → 软删除（`deleted_at`）→ 保留 7 天可恢复
- 一天多篇时，列表按 `created_at DESC`；同一天仅在首篇前显示日期分隔条

---

## 四、页面结构（4  + 1 个设置页）

| 页面 | 职责 | 备注 |
| --- | --- | --- |
| 解锁页 | Face ID 验证，冷启动与后台回前台触发 | 失败可重试；不做密码兜底（防止自锁） |
| 首页 / 时间轴 | 搜索框（常驻）、日记列表、日期分隔条、图片标识、悬浮「+」 | 顶部右侧切换日历视图 |
| 日历页 | 月历，有记录日期高亮打点，点击进入当日列表 | |
| 编辑 / 详情页 | 沉浸式输入、日期选择（补写）、插入图片、字号、信纸、撤销重做、删除 | 首次进入自动弹出键盘，减少一次点击 |
| 设置页 | 深色模式/跟随系统、字号、Face ID 开关、数据统计（篇数/字数）、导出全部、批量导入、清空缓存 | |

> **交互铁律**：新手指引、空状态插画、动效这些全部放到 Phase 4 之后。前三个阶段只做「能用」。

---

## 五、开发上线步骤

> 按每周 8–12 小时业余时间估算，实际工期约 3–5 周。

### Phase 0 · 打通链路（3–5 天）— 最重要的一步

**目标：第一天就让一个空白 App 出现在你手机上。**

1. **立刻去注册 Apple Developer 个人账号**（¥688/年，审核 1–2 个工作日）
   - 这是唯一的硬性收费，且**卡脖子**，必须先办
2. Windows 安装 Flutter SDK + VS Code，`flutter doctor` 检查
3. 创建项目 `flutter create`，禁用不需要的平台保留 iOS + Windows
4. 建 GitHub 仓库，配置 Codemagic workflow（`codemagic.yaml`）
5. 生成 iOS 分发证书（Windows 上用 OpenSSL 生成 CSR）→ 上传 .p12 与 Provisioning Profile 到 Codemagic
6. 在 App Store Connect 创建 App 记录（需准备 App 名称、Bundle ID、**隐私政策 URL**）
   - 免费方案：GitHub Pages 挂一个纯静态隐私政策页即可
7. **跑通第一次 CI：出一个能装到 iPhone 的空白 App**

> ⚠️ 这一步绝对不能跳过或延后。后面每改一次 UI 都要靠它验证，早一天打通，后面少一周痛苦。

### Phase 1 · 写与存（5–7 天）

- drift 建表、DAO 层
- 首页时间轴列表、日期分隔、空状态提示
- 新建（默认今天，可切历史日期补写）
- 编辑页沉浸式输入、自动草稿保存、删除二次确认
- 导出单篇为 Markdown/TXT

**产出：能连续记录一周，证明习惯成立。**

### Phase 2 · 找与安全（3–5 天）

- 全文搜索（LIKE，覆盖正文 + 日期关键词）
- 日历视图（有记录日期打点 → 当日列表）
- Face ID 解锁 + 后台自动锁定
- 设置页：深色模式、字号、数据统计

### Phase 3 · 图片与迁移（3–5 天）

- 相册多选插入、编辑期删除已插图
- 导出：`Markdown + assets 图片包` / 全部导出为 zip
- 批量导入 TXT / Markdown

### Phase 4 · 打磨（5–7 天）

- 国风信纸第 1 款、字体与字号三档的实际观感调校
- 撤销/重做、空内容不可保存、误删保护（回收站）
- 性能验证：灌入 1000+ 条假数据，确认列表与搜索不卡

### Phase 5 · 真机 30 天（30 天）

- 日常真实使用，随时把别扭的地方记进 todo
- 每周推一次 CI 构建更新到 TestFlight
- **每周做一次导出到 iCloud / 文件 App**——这是你唯一必须养成的习惯

### Phase 6 · 分发（可选，按需）

| 目标 | 做法 | 成本 |
| --- | --- | --- |
| 自用 | TestFlight 内部测试 | ¥688/年（已付） |
| 免费替代 | SideStore / AltStore 侧载 | ¥0，代价是每 7 天需重签（SideStore 可自动续签） |
| 给朋友用 | TestFlight 外部测试 | 需 Beta 审核（约 1 天） |
| 上架 App Store | 提交审核 | 需隐私政策页、截图、审核约 1–3 天 |
| 上架国内安卓商店 | — | 需软著（30–60 天）+ 各类资质，自用不推荐 |

---

## 六、成本清单

| 项 | 费用 |
| --- | --- |
| Apple Developer 个人账号 | **¥688 / 年**（必需，唯一硬性支出） |
| Codemagic | ¥0（500 分钟/月免费额度） |
| GitHub 私有仓库 | ¥0 |
| 隐私政策静态页（GitHub Pages） | ¥0 |
| Flutter / VS Code / 全部依赖包 | ¥0 |
| Mac 设备 | ¥0（云端 CI 替代） |

**总计：¥688 / 年。**

> 想完全不花钱？**见 § 附录 · 零花销方案**，可以做到 ¥0 且仍然是真原生 App，代价是每 7 天要重签。

---

## 七、风险清单

| # | 风险 | 缓解措施 |
| --- | --- | --- |
| 1 | **没有 Mac，看不到真机效果** | Windows 桌面端调试 90% UI；每个阶段末出一个 CI 包在手机上验收一次，不要等全做完才看 |
| 2 | 证书/描述文件过期导致 CI 失败 | 用日历记下过期日；Codemagic 支持 App Store Connect API Key 自动续签，优先用 API Key 而非 p12 |
| 3 | TestFlight build 90 天过期 | CI 一键重建，不在乎就设个季度提醒 |
| 4 | Apple 账号审核 1–2 天阻塞 | Phase 0 第一天就提交注册 |
| 5 | **数据丢失**（唯一真正致命的） | 养成每周导出到 iCloud 的习惯；这是本 App 里唯一不能省的动作 |
| 6 | 自己把自己锁在门外 | 不设备用密码，只依赖 Face ID（面容失败可回退系统密码解锁手机） |
| 7 | 半途 app 就写不下去 | Phase 1 结束即放开日常使用，不要憋大版本 |

---

## 八、裁剪后的 V1.0 范围对照表

| 原 PRD 功能 | 处置 |
| --- | --- |
| 新建 / 补写 / 编辑 / 删除 | ✅ 保留 |
| 自动保存草稿 | ✅ 保留 |
| 字号三档 | ✅ 保留（Phase 4） |
| 信纸 3–5 款 | 🔽 减为 1 款 |
| 撤销重做 | ✅ 保留（Phase 4） |
| 图片插入 / 删除 | ✅ 保留 |
| 时间轴 / 日历双视图 | ✅ 保留 |
| 全文 + 日期搜索 | ✅ 保留（LIKE 实现） |
| 4–6 位数字密码 | ❌ 砍（保留 Face ID） |
| 生物识别 + 后台隐藏 | ✅ 保留 |
| 定期本地自动备份 | 🔄 改为手动导出到系统文件 App |
| 导出 TXT / PDF | 🔽 只做 Markdown/TXT + zip，PDF 交给系统打印 |
| 数据统计（篇数/字数） | ✅ 保留 |
| 深浅色模式 | ✅ 保留 |
| 安卓适配 | ❌ 砍 |
| 批量导入 | ➕ **新增**（原 PRD 缺失） |
| 回收站（误删保护） | ➕ **新增**（软删除） |

---

## 九、下一步动作

按优先级，现在可以立刻开始的三件事：

1. **注册 Apple Developer 个人账号**（¥688/年，审核 1–2 个工作日）
   - 想零花销就用**侧载路线（见附录）**，本节第 1、5、6 步可跳过，直接打 unsigned IPA
   - 无论如何建议早日决策；付费路线下账号审核期间可以做下面的事
2. **Windows 装 Flutter SDK，`flutter doctor` 通过**
3. **创建项目骨架 + GitHub 仓库 + Codemagic 打通首次 iOS 构建**

三件事都跑通后，进入 Phase 1 数据层与首页开发。

---

## 附录 · 零花销方案（不买 ¥688 开发者账号）

**结论先行：可以做到 ¥0，而且仍然是跑在你 iPhone 上的真原生 Flutter App。** 核心是用免费的 Apple ID 侧载（sideload），绕开 Apple Developer 会员。

### A. 三条零成本路线对比

| | **路线 1：AltStore / Sideloadly 侧载**（推荐） | 路线 2：快捷指令 + iCloud Markdown | 路线 3：PWA 添加主屏幕 |
| --- | --- | --- | --- |
| 成本 | ¥0 | ¥0 | ¥0 |
| 形态 | **真原生 Flutter App** | 快捷指令 + 系统文件 App | 网页伪装成 App |
| Face ID | ✅ 可用（LocalAuthentication 无需付费） | 由系统锁屏承担 | ❌ 拿不到 |
| 桌面小组件 | ❌ 见下方限制 4 | ✅ 快捷指令小组件 | ❌ |
| 7 天重签 | 需要（AltStore 同 WiFi 可自动续） | 不需要 | 不需要 |
| 上手难度 | 中（首次要装 iTunes/iCloud + 开发者模式） | 低（约 30 分钟） | 低 |
| 是否需要云端 CI | 是（Codemagic 免费额度） | 否 | 否 |
| **数据安全** | ⭐⭐⭐⭐ 随系统备份 | ⭐⭐⭐⭐⭐ 纯 Markdown 在 iCloud | ⭐⭐ **iOS 会清理长期未访问的站点数据** |
| 适合谁 | **想真的把 App 做出来**（你的情况） | 只想马上有个能用的记录方式 | 临时体验，别当主力 |

> 路线 3 不选的原因：iOS 对长期无交互的站点会清理 IndexedDB/localStorage，日记数据放里面风险太高。借用可以，别当唯一存储。

### B. 路线 1 的详细链路

```
Windows 写 Flutter ──git push──> GitHub
                                     │
                          Codemagic 免费额度（macOS 机型）
                          flutter build ios --release --no-codesign
                          打包成 unsigned .ipa
                                     │ 下载 IPA 到本机
                                     ▼
                    AltStore / Sideloadly（Windows，用免费 Apple ID 签名）
                                     │ USB 或同一 WiFi
                                     ▼
                                你的 iPhone
```

不需要证书、不需要描述文件、不需要 App Store Connect——**免费 Apple ID 的签名由 AltServer 在本地完成**。

**Codemagic 侧的关键脚本**（产出未签名 IPA）：

```bash
flutter build ios --release --no-codesign
cd build/ios/iphoneos
mkdir -p Payload
cp -R Runner.app Payload/
zip -qry Runner.ipa Payload
```

`codemagic.yaml` 里把 artifacts 指向 `build/ios/iphoneos/Runner.ipa` 即可。

### C. 免费 Apple ID 的硬限制（这些必须提前知道）

1. **证书 7 天过期** → AltStore 在 AltServer 常驻 + 同一 WiFi 时会自动续签；出远门前手动 Refresh 一次即可
2. **同时最多 3 个侧载 App**（AltStore 自己占 1 个 → 你实际只剩 2 个位置）
3. 每周最多注册 10 个 App ID
4. ❌ **无法使用 App Groups 等能力** → 直接后果是 **桌面小组件做不了**。对日记 App 而言这是最真实的损失（少了一个轻点即写的入口）
5. ❌ 无 App Store Connect、**不能用 TestFlight** → 只能自己用，也**没法顺手分享给朋友**
6. iOS 16+ 需在「设置 → 隐私与安全性 → 开发者模式」手动开启

### D. AltStore Windows 配置的几个坑

- 必须装 **Apple 官网下载的 iTunes 和 iCloud**，**不能用 Microsoft Store 版本**——这是 90% 认证失败的原因
- AltServer 要**右键管理员运行**，并放行防火墙（至少专用网络）
- iTunes 里需勾选 Wi-Fi 同步
- 连接失败时先换 USB 线和接口，比调参数有用

> 嫌 AltStore 依赖 iTunes 麻烦：可用 **Sideloadly**（同样免费、Windows 原生，拖入 IPA 即可装），代价是每次都得手动连电脑重签，无法自动续。

### E. 什么时候该掏这 688 元

出现任意一条就别省了：

- 你希望有**桌面小组件**一键记录（免费签名做不到）
- 你希望一年不用管签名、出差旅行也不中断
- 你希望顺手把 App 分享给家人朋友（需要 TestFlight）
- 哪天重装后数据没能完整恢复——付费账号在可靠性上明显更好

### F. 我的建议

> **先用路线 1 花 ¥0 跑起来，验证「你会不会每天写」。**
> 等你连续写了 30 天、确认习惯成立，再花 688 元把体验补完整。
> **把钱花在验证之后，而不是之前。**

---

> 本文档为自用版本的裁剪方案。若后续希望转为面向多人/上架产品，需重新补入：Android 端、隐私政策与合规、数据加密强度、多机型适配矩阵、App Store 审核资料包。

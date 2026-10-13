# 极简日记 · JiJian

对标素记的个人自用日记 App。**仅 iOS**，离线优先，数据全本地。

仓库：<https://github.com/qianshuaiyixia/jijian>（私有）

## 当前进度

**Phase 0 —— 打通构建链路**（进行中）

- [x] Flutter 项目骨架（仅 iOS + Web 两个平台）
- [x] `codemagic.yaml`：产出未签名 IPA
- [x] 依赖解析跑通（`dart pub get` 成功）
- [x] 静态分析零问题（`dart analyze` → No issues found）
- [ ] **在你自己的终端里跑一次 `flutter run -d chrome`**（本机会话里 flutter 命令会卡住，见下方踩坑记录）
- [ ] 推送 GitHub + 首次 CI 构建
- [ ] AltStore 装到 iPhone

## 本机环境

| 项 | 值 |
| --- | --- |
| Flutter | 3.38.9（stable） |
| Flutter SDK 位置 | `F:\project\Kids\tools\flutter\flutter` |
| Chrome | `C:\Program Files\Google\Chrome\Application\chrome.exe` |
| Visual Studio | ❌ 未安装 → **Windows 桌面端目标不可用** |
| Android SDK | ❌ 不需要 |

> 因为没有 Visual Studio，本地**不能用 Windows 桌面端调试**。
> 替代方案：**Chrome 网页目标**（`flutter run -d chrome`），UI 迭代体验一样好。

## 本地开发

先告诉 Flutter Chrome 在哪（本机 Chrome 不在它默认的路径）：

```bash
export CHROME_EXECUTABLE="C:/Program Files/Google/Chrome/Application/chrome.exe"
```

然后：

```bash
flutter pub get
flutter run -d chrome
```

> ⚠️ 已知情况：本机会话里 `flutter pub get` 走代理很慢，可能要几分钟。
> 在你自己的终端里直接跑通常更快（网络不受代理影响）。

## 构建与安装到 iPhone

CI 会在每次 push 后自动产出 IPA（见 `codemagic.yaml`）：

```
Windows 写代码 → GitHub → Codemagic(云 macOS) → 未签名 IPA
                                                    ↓
                              AltStore / Sideloadly 用免费 Apple ID 签名 → iPhone
```

装到手机的步骤：

1. 从 Apple 官网装 **iTunes + iCloud**（**不能用 Microsoft Store 版本**，这是最常见的失败原因）
2. 装 AltServer（Windows），右键**管理员运行**，放行防火墙
3. iTunes 里开启 Wi-Fi 同步
4. AltServer → Install AltStore → 选 iPhone → 输入 Apple ID
5. iPhone：设置 → 通用 → VPN 与设备管理 → 信任；设置 → 隐私与安全性 → 打开**开发者模式**
6. 下载 CI 产出的 IPA → 分享给 AltStore → 自动签名安装

免费 Apple ID 的限制：证书 7 天过期（AltStore 同 WiFi 自动续）、同时最多 3 个侧载 App、**桌面小组件做不了**。

## Bundle ID

`cn.local.jijian`

## 本机踩坑记录（会反复遇到）

**1. Flutter 命令静默卡死 → 删掉僵尸锁**

如果某个 `flutter` 进程被强杀（比如超时中断），它会在下面这个位置留下锁文件：

```
F:\project\Kids\tools\flutter\flutter\bin\cache\lockfile
```

之后**所有** flutter 命令都会无限期等待这把锁，表现为**零输出、不报错、就是不动**。
解决：确认没有残留的 dart.exe 进程后，直接删掉这个 lockfile。

**2. 首次 `flutter pub get` 很慢**

本机会话里第一次拉依赖可能要十几分钟（走代理），期间**看不到任何输出**，容易被误判成卡死。
判断是否在推进：观察 Pub 缓存目录的包数量是否在增长。

```
C:\Users\13167\AppData\Local\Pub\Cache\hosted\pub.dev\
```

第二次开始有缓存后就会很快（几秒）。

**3. `flutter xxx` 的输出经常被吞**

在本机会话里，`flutter` 包装命令（ analyze / build 等）重定向到文件或管道后常常拿不到输出。
替代办法：直接用 Dart SDK 的等价命令，输出正常可见：

```bash
dart analyze      # 代替 flutter analyze
dart pub get      # 代替 flutter pub get
```

**4. `withOpacity` 已废弃**

Flutter 3.27+ 请用 `.withValues(alpha: x)`。

**5. `flutter build` / `flutter run` 在本机会话里跑不完**

依赖和分析都能跑（用 `dart` 等价命令），但 `flutter build web` / `flutter run`
在实际执行阶段会静默卡住十几分钟无任何输出 —— 怀疑是编译阶段需要访问被代理拦截的资源。

这不影响真实交付：CI 在云端 macOS 上跑，`flutter build ios` 与公司本地网络无关。
你只需要在**自己的终端**里执行即可（那里网络不受限）：

```bash
export CHROME_EXECUTABLE="C:/Program Files/Google/Chrome/Application/chrome.exe"
flutter run -d chrome
```

## 目录结构

```
lib/            源码（Phase 1 起填充）
ios/            iOS 工程（必须提交，CI 依赖它）
web/            Chrome 调试用（后续放 sqlite3.wasm / drift_worker.js）
codemagic.yaml  CI 配置，产出未签名 IPA
```

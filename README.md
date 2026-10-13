# 极简日记 · JiJian

对标素记的个人自用日记 App。**仅 iOS**，离线优先，数据全本地。

## 当前进度

**Phase 0 —— 打通构建链路**（进行中）

- [x] Flutter 项目骨架（仅 iOS + Web 两个平台）
- [x] `codemagic.yaml`：产出未签名 IPA
- [ ] `flutter pub get` 跑通
- [ ] Chrome 本地调试跑起来
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

## 目录结构

```
lib/            源码（Phase 1 起填充）
ios/            iOS 工程（必须提交，CI 依赖它）
web/            Chrome 调试用（后续放 sqlite3.wasm / drift_worker.js）
codemagic.yaml  CI 配置，产出未签名 IPA
```

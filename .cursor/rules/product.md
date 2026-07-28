---
description: Product context — what this is, who it's for, and where it's going. Applies to every interaction.
alwaysApply: true
---

# Product: Legado Flutter

## 产品定义 (What)

Legado Flutter 的总体目标是将 [Jingshiro/legado](https://github.com/Jingshiro/legado) 的 Android/Kotlin 实现重构为 Rust + Flutter 跨平台版本，使用 Flutter 构建 UI 层、Rust 承担核心引擎，目标覆盖 iOS/Android/Desktop/Web。Jingshiro/legado 是行为、数据格式和 UI 兼容性的基线；UI 复刻是重构验收的一部分。项目无商业化目标，保持开源免费。

## 用户与场景 (Who & When)

- **主用户**：熟悉 Legado 的中文读者，日常使用书源搜索和书架管理，关注阅读进度同步和净化体验。
  - **使用场景**：通勤、睡前、离线环境（如地铁），需要稳定的离线阅读能力。
  - **核心诉求**：数据自主可控、高度可定制、无广告干扰。
  - **痛点**：原版 Android 应用在解析复杂站点时性能不足，长期维护困难。
- **次用户**：书源作者/调试者，需要规则编辑和调试面板来维护和验证书源有效性。

## 核心工作流 (Key Flows)

1. **发现并阅读**：启用书源 → 搜索书籍 → 加入书架 → 开始阅读。
2. **本地导入**：导入本地文件（txt/epub）→ 自动解析目录与章节 → 阅读。
3. **个性化阅读**：阅读中调整主题/字体/TTS/替换净化 → 设置自动保存并生效。

## 体验原则 (UX Principles)

1. **性能优先**：列表滑动与翻页必须流畅不卡顿，章节解析在后台快速完成。
2. **本地优先**：阅读数据默认存储在本地，不主动上传云端。WebDAV 仅为用户主动选择的备份/同步手段。
3. **不干扰用户**：无推送、无社交、无用户行为追踪。

## 语气与文案 (Tone)

简洁务实，贴近原版「阅读」风格。错误提示必须提供可操作的建议，例如：「书源请求失败，请检查网络或禁用该源」，避免使用含糊不清的「出错了，请重试」。

## 竞品定位 (Positioning)

- 不同于微信读书/起点：不提供官方书库，无社交和商业化功能。
- 不同于纯本地阅读器：支持网络书源扩展，内容获取由用户自主配置。
- 核心差异：**Rust 引擎提供更快的解析性能，且真正实现跨平台（iOS/Android/Desktop）**。

## 路线图 (Roadmap)

- **R0-R3（核心迁移）**：将规则解析、网络、数据库、阅读会话和缓存从 Android/Kotlin 边界迁移到 Rust + Flutter 分层架构。
- **R4-R5（行为与数据兼容）**：对齐目录、正文、进度、备份、书签和 WebDAV 数据链路，保留 Jingshiro/legado 的可观察行为。
- **R6（平台与 UI 收敛）**：按功能域整理 Flutter UI，完成多平台适配和与 Jingshiro/legado 的 UI/交互验收。

## 法律与合规 (Legal)

- 本地优先，默认不上云收集阅读数据（用户主动 WebDAV/备份除外）。
- 书源与内容合规由用户自负；应用本身不提供任何官方侵权书源服务。

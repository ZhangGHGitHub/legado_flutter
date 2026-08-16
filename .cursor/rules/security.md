---
description: Security checklist and guardrails. Applies to all code that handles user input, authentication, authorization, or external data.
alwaysApply: true
---

# Security: Legado Flutter

## 核心安全原则

- **无账号体系**：本应用无用户账号、无服务端 RBAC（基于角色的访问控制），所有数据归属用户本地。
- **本地优先**：所有敏感数据默认仅存本地，不上传任何云端服务（用户主动触发的 WebDAV 备份除外）。
- **不收集行为数据**：应用不追踪、不记录、不上传任何用户阅读行为数据。

---

## 数据存储与凭据安全

### 凭据存储

- **WebDAV 凭据**：仅存储在本地 SharedPreferences 中，由用户自行管理。
- **禁止硬编码**：严禁在代码的任何位置（包括注释、示例）中写入真实的密钥、URL 或凭据。
- **环境变量文件**：如需在开发中使用测试凭据，通过 `.env` 文件管理，且 **`.env` 必须加入 `.gitignore`**，不得提交到仓库。
- **提交前自查**：可用 `gitleaks` 等工具扫描仓库，确保无凭据泄露。

---

## 输入与渲染安全

### 书源与正文处理

- **禁止直接渲染不可信 HTML**：从书源获取的 HTML/正文内容，不得直接通过 `WebView` 或 `HtmlWidget` 渲染。必须经过净化处理（如使用 `flutter_html` 的 `sanitize` 选项），移除 `<script>`、`<iframe>` 等危险标签。
- **URL 合法性校验**：书源中配置的请求 URL 需做基本校验，防止恶意书源指向内网地址（SSRF 风险）。Dart（`SsrfGuard`）与 Rust（`http::ssrf`）均校验字面量 host；书源 HTTP / Dio 导入对**重定向 Location 逐跳**再校验。不做 DNS 解析（无法防 DNS rebinding）。**不约束** Web API 本机监听路径。

### 本地文件导入

- 导入本地 txt/epub 文件时，需校验：
  - 文件大小不超过合理阈值（如 50MB），防止 OOM。
  - 文件格式有效性，防止恶意构造文件导致解析崩溃。

---

## SQL 注入防护

- **强制参数化查询**：所有 SQLite 操作（无论 Dart 侧还是 Rust 侧）必须使用参数化查询，严禁通过字符串拼接构造 SQL 语句。
- **示例**：

```dart
// ❌ 错误
db.rawQuery('SELECT * FROM books WHERE id = $id');

// ✅ 正确
db.query('books', where: 'id = ?', whereArgs: [id]);
```

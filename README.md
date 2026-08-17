# LLM_Chat

一个 Flutter 编写的 Android 大模型对话客户端。自带应用内浏览器、工具调用（ReAct）、提示词模板与本地会话管理，风格参考 llama.cpp 的对话框。

## 功能

### 对话
- 多提供方/多模型管理，OpenAI 兼容 API（DeepSeek / vLLM / llama.cpp server 等）
- 流式输出（30fps 合并渲染），思考内容（reasoning）折叠展示，思考深度三档
- 分支对话：消息级分支 + 版本切换（llama.cpp 树状分支风格）
- 消息编辑 / 重新生成 / 复制 / 删除，截断（truncated）标记与续写
- 文字替换规则：显示层与模型层的双向文本替换（如模型名 → 昵称）
- AI 自动生成会话标题（可配置提示词与模型）

### 渲染
- Markdown：代码高亮（VS Code Dark+ 配色）、表格、链接
- LaTeX 公式（flutter_math，行内 + 块级，沉浸式渲染）
- Mermaid 图表（WebView 渲染 + 光栅化缓存，点击全屏缩放）
- Artifacts 预览（html / svg 代码块内嵌 WebView，可全屏）

### 工具调用（ReAct）
- 内置工具：获取当前时间 / 地理位置 / 联网搜索（DeepSeek 原生 web_search 服务端工具）
- MCP 服务器：可配置多个远程 MCP，工具按会话启用
- 工具循环上限可配置，轮次耗尽有明确提示
- 模型以 XML 文本输出的工具调用也能识别执行（llama.cpp 风格兜底）

### 其他
- 应用内浏览器（Via 思路：复用系统 WebView，零额外体积）
- 提示词模板：内置 + 自定义，两列网格，长按编辑/删除
- 上下文占用圆环（API tokenize 精确计数，可显示百分比）
- 归档 / 锁定 / 自动清理会话，本地存储（SharedPreferences）
- 液态玻璃 UI（Liquid Glass），亮暗双主题，沉浸式系统栏

## 构建

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64
```

产物：`build/app/outputs/flutter-apk/app-release.apk`（arm64-v8a）。

## 权限说明

| 权限 | 用途 |
|---|---|
| INTERNET | 访问模型 API / MCP / 搜索 |
| ACCESS_COARSE/FINE_LOCATION | 内置工具「获取地理位置」（模型可查询设备位置） |

不收集任何数据；所有会话、配置、密钥仅保存在设备本地。

## 许可

MIT

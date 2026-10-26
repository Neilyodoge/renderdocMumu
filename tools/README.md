# 本地工具

`tools/` 是附加工具的父目录，后续其他工具可以各建一个子目录放在这里。RenderDoc 源码继续保持原布局，便于沿用原构建流程。

- `renderdoc-portable/`：本机编译的 RenderDoc 1.47 Windows x64 运行包、x86 捕获辅助程序和逐文件校验清单。
- `renderdoc-mcp/`：与本机安装版本一致的 MCP 服务端和 RenderDoc 扩展源码，包含依赖锁文件及原有许可。
- `setup-renderdoc.ps1`：解压校验、扩展安装、MCP 依赖安装和启动入口。
- `.runtime/`：脚本生成的运行目录，不提交到 Git。

## 直接运行 RenderDoc

克隆本仓库，或在 GitHub 使用 **Code → Download ZIP** 后解压。在仓库根目录打开 PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-renderdoc.ps1 -Launch
```

脚本校验 ZIP 的 SHA-256 和解压后的全部文件，启动 `tools/.runtime/renderdoc-1.47/qrenderdoc.exe`。此运行包直接保存在 Git 中，Fork 会保留，无需额外下载 Release 附件。

运行环境为 Windows x64。新机器若缺少 MSVC 运行库，请安装微软官方 [VC++ x64 运行库](https://aka.ms/vs/17/release/vc_redist.x64.exe)；捕获 32 位应用还需要 [x86 运行库](https://aka.ms/vs/17/release/vc_redist.x86.exe)。实际回放仍依赖 GPU 和驱动对捕获使用的图形功能的支持。

这是现有 Development 构建的备份，构建提交为 `7ae8ff9bec03bcfc4473f08f5a4adabd907a755c`。不含调试符号、编译中间文件、额外 Android/着色器工具插件或 RDC 抓帧素材。

## 同时配置 MCP

先安装 [uv](https://docs.astral.sh/uv/getting-started/installation/)，然后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-renderdoc.ps1 -InstallBridge -InstallMcp -Launch
```

第一次安装 Python 依赖需要联网。脚本使用 `uv.lock` 锁定依赖，在 `tools/renderdoc-mcp/.venv/` 建立独立环境；扩展放到 `%APPDATA%/qrenderdoc/extensions/renderdoc_mcp_bridge/`。已有扩展内容不同时，先完整备份到同级的 `extension-backups/`，再覆盖同名文件。

在 RenderDoc 的 **Tools → Manage Extensions** 中启用 **RenderDoc MCP Bridge**，再在 MCP 客户端添加 stdio 服务：

- 命令：`uv`
- 参数：`--directory`、`仓库绝对路径/tools/renderdoc-mcp`、`run`、`--locked`、`renderdoc-mcp`

这是文件 IPC 版本，服务端通过临时目录下的 `renderdoc_mcp/` 与扩展通信。扩展部分旧提示仍写着端口 19876，但实际通信实现是文件轮询。多台机器分别配置即可；同一 Windows 用户下建议只开启一个供 MCP 操作的 RenderDoc 实例。

## 来源与恢复

MCP 项目来源为 [halby24/RenderDocMCP](https://github.com/halby24/RenderDocMCP)，本目录保存已安装版本所对应的本地源码快照；原有说明和 MIT 许可保留在其目录中。RenderDoc 与打包的第三方文件沿用各自许可。

PySide2 构建依赖另存于仓库根目录的 `qrenderdoc_3rdparty.zip`，恢复方法见 [LOCAL_SETUP.md](../LOCAL_SETUP.md)。日常使用运行包不需要再解压这份构建依赖。

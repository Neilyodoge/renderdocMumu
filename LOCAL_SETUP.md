# 本地 PySide2 依赖备份

本仓库在 RenderDoc 1.47 的 Yi-Meng 分支基础上，保存本地使用的 PySide2 依赖包。

## 保存的内容

- `qrenderdoc_3rdparty.zip`：70 个文件，包含 Win32/x64 的 PySide2 绑定、头文件和原有 LGPLv3 许可文件。
- ZIP 解压后为 `qrenderdoc/3rdparty/pyside/`。提交前已确认包内文件与本地已安装文件逐个一致。
- `_qrenderdoc_3rdparty_extract/` 是同一压缩包的临时解压副本，已加入忽略列表。

ZIP SHA-256：`9fdf4b298df843571120ff139b745b4183d9c332b157f1982f4242c96e038f1c`

## 恢复依赖

在仓库根目录运行 PowerShell：

```powershell
Expand-Archive -LiteralPath .\qrenderdoc_3rdparty.zip -DestinationPath . -Force
```

这个命令会恢复或覆盖 `qrenderdoc/3rdparty/pyside/` 下的文件。该目录沿用上游的 Git 忽略规则。

这是构建依赖备份，不是独立的 RenderDoc 安装包。完整构建步骤见 [官方构建说明](docs/CONTRIBUTING/Compiling.md)。

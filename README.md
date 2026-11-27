# Chamomile Emacs 配置

`early-init.el` 负责首帧设置、包激活缓存和启动期 GC；`init.el` 只指定模块的加载顺序。自定义函数和变量统一使用 `chamomile/` 前缀。

| 模块 | 职责 |
| --- | --- |
| [`init-packages.el`](lisp/init-packages.el) | 软件源、包安装、独立的 `custom.el` |
| [`init-ui.el`](lisp/init-ui.el) | 主题、GUI 字体、相对行号和滚动 |
| [`init-editor.el`](lisp/init-editor.el) | 编辑行为、多光标、行尾空白和快捷命令 |
| [`init-navigation.el`](lisp/init-navigation.el) | Ido / Smex、窗口管理、Dired、搜索、Git 和头文件跳转 |
| [`init-languages.el`](lisp/init-languages.el) | 编程主模式、缩进和编译 |
| [`init-lsp.el`](lisp/init-lsp.el) | Eglot 自动连接和 Corfu 自动补全 |
| [`init-org.el`](lisp/init-org.el) | Org 议程、捕获、计时和剪贴板链接 |

模块文件在启动时主要登记快捷键、后缀和 hook。主题和 Ido 立即启用；Winner 从启动就记录窗口布局。Magit、Smex、Windmove、语言主模式和 Org 工具在实际用到时才加载。议程目录仅在加载 Agenda 或 Capture 时创建。

首次启用包激活缓存时，可执行 `M-x package-quickstart-refresh`。`M-x emacs-init-time` 可查看启动耗时。

## 快捷键速查

`C-` 表示 Ctrl，`M-` 通常表示 Alt，`S-` 表示 Shift，`RET` 表示回车。空格分隔的是依次按下的组合，例如 `C-x C-f` 是先按 Ctrl+x，再按 Ctrl+f。`M-X` 的 `X` 是大写，需要按住 Shift。

### 编辑与多光标

| 快捷键 | 功能 |
| --- | --- |
| `C-,` | 复制当前行，光标留在新行的相同位置 |
| `C-c w` | 清除行尾空白（有选区时只清除选区内的空白） |
| `C-S-c C-S-c` | 先选中多行，再为选区内的每一行添加一个光标 |
| `C->` / `C-<` | 先选中一段文字，再向后／向前添加一个匹配的光标 |
| `C-c C-<` | 为缓冲区内所有与选区匹配的位置添加光标 |
| `C-c C-s` | 跳过最后一个向后选中的匹配，改选下一个 |
| `C-c C-d` | 移除最后一个向后添加的匹配光标 |
| `C-c C-j` | 在 Emacs Lisp 缓冲区中，求值光标前的表达式并把结果插入缓冲区 |

### 文件、缓冲区与搜索

| 快捷键 | 功能 |
| --- | --- |
| `C-x C-f` / `C-x b` | 用 Ido 打开文件／切换缓冲区 |
| `C-n` / `C-p` | 在 Ido 的纵向候选列表中选择下一项／上一项 |
| `M-x` / `M-X` | 用 Smex 搜索所有命令／当前主模式的命令 |
| `C-x C-g` | 在另一个窗口打开光标处的文件；在 `#include` 行上会查找 C/C++ 头文件 |
| `C-c s` | 从当前目录递归搜索选中的文字；没有选区时提示输入搜索条件 |
| `C-c i m` | 用 Imenu 跳转到当前缓冲区内的函数、类型或其他条目，列表由主模式提供 |

### 窗口、Dired 与 Git

| 快捷键 | 功能 |
| --- | --- |
| `Shift + 方向键` | 切换到该方向的窗口 |
| `C-c <left>` / `C-c <right>` | 用 Winner 撤销／重做窗口布局，不影响文件内容 |
| `C-x d` | 打开 Dired 目录缓冲区 |
| `C-x C-j` | 跳到当前文件所在的 Dired 目录，并定位到该文件；已在 Dired 中时，跳到上一级并定位到原目录 |
| `C-c C-e` | 在 Dired 中进入可写模式，可直接编辑文件名进行批量重命名 |
| `C-c C-c` | 在可写 Dired 中提交修改 |
| `C-x g` | 打开当前 Git 仓库的 Magit 状态页面 |

### 编译与代码跳转

| 快捷键 | 功能 |
| --- | --- |
| `F5` / `F6` | 输入命令并开始编译／重新运行上一次编译命令 |
| `M-.` / `M-,` | 跳转到定义／返回跳转前的位置；Eglot 接管时由语言服务器提供定义位置 |
| `↑` / `↓`（或 `M-p` / `M-n`） | Corfu 弹窗显示时选择上一项／下一项 |
| `RET` / `C-g` | 确认 Corfu 候选／关闭弹窗 |

### Org 议程、任务与链接

| 快捷键 | 功能 |
| --- | --- |
| `C-x a` | 打开议程菜单：`u` 看未安排时间且无截止日期的个人待办，`p` 看个人议程，`w` 看工作议程 |
| `C-c c` | 打开捕获菜单：`p` 记录普通任务，大写 `K` 从剪贴板 URL 生成链接任务；都写入 `~/Documents/Agenda/Tasks.org` |
| `C-c C-x j` | 跳转到当前正在计时的 Org 任务 |
| `C-x p i` | 抓取剪贴板 URL 的网页标题，并插入 Org 链接 |
| `C-x p t` | 在当前位置从剪贴板 URL 插入一个带链接的 TODO |
| `C-x p w` | 复制当前 Org 标题的纯文本，不含 TODO 状态和标签 |

## LSP 和自动补全

打开本地源码时，只有相应服务器在 Emacs 的 `exec-path` 中才会自动连接：`clangd`（C/C++）、`rust-analyzer`（Rust）、`zls`（Zig）、`typescript-language-server`（JS/TS/TSX）、`lua-language-server`（Lua）和 `bash-language-server`（Bash/sh）。使用 rustup 时，Rust 项目选用的工具链需要安装 `rust-analyzer` 组件。

Eglot 接管后，输入两个字符并短暂停顿，或输入 `.` 时，有候选就会在光标旁弹出 Corfu。不需要按补全快捷键。

Flymake 会在行尾显示最严重的一条诊断（仅显示，不修改源码）。用 `M-x flymake-show-buffer-diagnostics` 查看当前文件的完整诊断列表。

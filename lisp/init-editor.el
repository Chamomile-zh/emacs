;;; init-editor.el --- Editing defaults and text commands -*- lexical-binding: t; -*-

;;;; 文件保存与退出

;; 不创建备份和锁文件；用短回答确认操作。
(setq make-backup-files nil
      create-lockfiles nil
      use-short-answers t)

;; 自动保存只写恢复副本，不覆盖源文件；用完整路径的散列区分同名文件。
(let ((directory (expand-file-name "auto-save/" chamomile/cache-dir)))
  (unless (file-directory-p directory)
    (with-file-modes #o700
      (make-directory directory t)))
  (setq auto-save-default t
        auto-save-file-name-transforms `((".*" ,directory sha256))))

;; C-x C-c 或关闭窗口退出：用底部文字确认未保存的修改，不弹系统对话框。
(defun chamomile/exit-with-text-prompts (exit &rest args)
  "Run EXIT with ARGS, using text prompts instead of GUI dialogs."
  (let ((use-dialog-box nil)
        (use-dialog-box-override nil))
    (apply exit args)))

(advice-add 'save-buffers-kill-emacs :around #'chamomile/exit-with-text-prompts)

;; 打开文件或 Dired 时即恢复位置，并自动重载未编辑的外部改动。
(global-auto-revert-mode 1)
(save-place-mode 1)

;;;; 基础编辑

;; 禁用提示音，启用系统剪贴板和主选区；缩进用空格，Tab 显示宽度为 4。
(setq ring-bell-function 'ignore
      select-enable-clipboard t
      select-enable-primary t)
(setq-default indent-tabs-mode nil
              tab-width 4)

;; 自动闭合括号；选中文本后直接输入可替换选区。
(electric-pair-mode 1)
(delete-selection-mode 1)

;; Rainbow Delimiters：按嵌套深度给括号上色，首次进入编程缓冲区时才加载。
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; M-/：取消旧的手动文本补全；自动弹窗由 init-lsp.el 中的 Corfu 提供。
(keymap-global-unset "M-/")

;;;; 多光标和常用编辑命令

;; Multiple Cursors：同时编辑多行或多处匹配，首次按键才加载。
(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)           ; 给选区中的每一行加光标
         ("C->" . mc/mark-next-like-this)           ; 向后加选匹配
         ("C-<" . mc/mark-previous-like-this)       ; 向前加选匹配
         ("C-c C-<" . mc/mark-all-like-this)        ; 加选缓冲区内所有匹配
         ("C-c C-s" . mc/skip-to-next-like-this)    ; 跳过当前匹配，改选下一处
         ("C-c C-d" . mc/unmark-next-like-this)))  ; 移除最后一个向后的匹配光标

;; C-,：复制当前行，保持光标在同一列。
(defun chamomile/duplicate-line ()
  "Duplicate the current line and keep point at the same position on it."
  (interactive)
  (let ((offset (- (point) (line-beginning-position)))
        (line (buffer-substring (line-beginning-position) (line-end-position))))
    (end-of-line)
    (insert "\n" line)
    (forward-char (- offset (length line)))))

(keymap-global-set "C-," #'chamomile/duplicate-line)

;;;; 行尾空白

;; 默认高亮行尾空白；C-c w 手动清理，部分语言保存时自动清理。
(setq-default show-trailing-whitespace t)
(keymap-global-set "C-c w" #'delete-trailing-whitespace)

(defun chamomile/hide-trailing-whitespace ()
  "Hide trailing whitespace in the current non-editing buffer."
  (setq-local show-trailing-whitespace nil))

(dolist (hook '(term-mode-hook vterm-mode-hook compilation-mode-hook
                dired-mode-hook minibuffer-setup-hook))
  (add-hook hook #'chamomile/hide-trailing-whitespace))

(defun chamomile/auto-clean-whitespace-on-save ()
  "Delete trailing whitespace when saving the current buffer."
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(dolist (hook '(c-mode-hook c++-mode-hook c-ts-mode-hook c++-ts-mode-hook
                rust-mode-hook zig-mode-hook))
  (add-hook hook #'chamomile/auto-clean-whitespace-on-save))

;;;; Emacs Lisp 编辑

;; C-c C-j：求值光标前的表达式并插入结果，仅在 Emacs Lisp 模式下绑定。
(with-eval-after-load 'elisp-mode
  (keymap-set emacs-lisp-mode-map "C-c C-j" #'eval-print-last-sexp))

;;;; 文档阅读（PDF / EPUB）

;; EMuReader：基于 MuPDF 的通用文档阅读器，替代 doc-view 和 nov.el。
;; find-file 打开 PDF/EPUB/MOBI/CBZ 等会自动进入 emureader-mode。
;; 依赖系统库 libmupdf（Arch: sudo pacman -S libmupdf）；首次使用前需执行
;; M-x emureader-build 编译原生动态模块，之后无需重复。
(use-package emureader
  :defer t
  :config
  ;; 深色主题下反转文档颜色，让白底 PDF 变成暗色；单文档可用
  ;; M-x emureader-dark-mode 临时切换。
  (emureader-global-dark-mode 1))

(provide 'init-editor)
;;; init-editor.el ends here

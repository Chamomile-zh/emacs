;;; init-tools.el --- Tsoding workflow tools & custom functions -*- lexical-binding: t; -*-

;; 1. 禁用旧的手动文本补全键，改用代码缓冲区的 Corfu 自动补全。
(keymap-global-unset "M-/")

;; 2. 多光标批量编辑
(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-c C-s" . mc/skip-to-next-like-this)
         ("C-c C-d" . mc/unmark-next-like-this)))

;; 3. Git 集成
(use-package magit
  :bind ("C-x g" . magit-status))

;; 4. 多语言轻量主模式支持（按后缀延迟加载，零启动开销）
(use-package rust-mode
  :mode "\\.rs\\'")

(use-package zig-mode
  :mode "\\.zig\\'"
  :config
  (setq zig-format-on-save nil))

(use-package go-mode
  :mode "\\.go\\'")

(use-package lua-mode
  :ensure nil
  :mode "\\.lua\\'")

(use-package typescript-mode
  :mode (("\\.ts\\'" . typescript-mode)
         ("\\.tsx\\'" . rc/typescript-tsx-mode))
  :config
  ;; 区分 TSX 的 LSP 语言 ID，不依赖额外的 tree-sitter grammar。
  (define-derived-mode rc/typescript-tsx-mode typescript-mode "TSX")
  (setq auto-mode-alist
        (delete '("\\.tsx?\\'" . typescript-mode) auto-mode-alist)))

(use-package cmake-mode
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))

(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'"))

(use-package toml-mode
  :mode "\\.toml\\'")

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :config
  (setq python-indent-offset 4))

;; 5. 一键编译与 ANSI 色彩渲染
(setq compilation-scroll-output 'first-error)
(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<f6>") 'recompile)

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

;; 6. 分屏窗口快速切换（Shift + 方向键直接移动焦点）
(windmove-default-keybindings)

;; 7. 误关分屏撤销与恢复（C-c <left> 撤销布局，C-c <right> 重做布局）
(use-package winner
  :ensure nil
  :config
  (winner-mode 1))

;; 8. Dired 双栏极简文件管理
(use-package dired
  :ensure nil
  :init
  (setq dired-dwim-target t
        dired-listing-switches "-alh --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)
  :hook
  (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
              ("C-c C-e" . wdired-change-to-wdired-mode)))

;; 9. Tsoding 自写复制当前行函数（保留列光标位置）
(defun rc/duplicate-line ()
  "Duplicate current line and keep column position."
  (interactive)
  (let ((column (- (point) (line-beginning-position)))
        (line (let ((s (thing-at-point 'line t)))
                (if s (string-remove-suffix "\n" s) ""))))
    (move-end-of-line 1)
    (newline)
    (insert line)
    (move-beginning-of-line 1)
    (forward-char column)))

(global-set-key (kbd "C-,") 'rc/duplicate-line)

;; 10. Tsoding 选中文本项目全局搜索（C-c s）
(defun rc/rgrep-selected (beg end)
  "Search for selected region across the project using rgrep."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point) (point))))
  (let ((selection (buffer-substring-no-properties beg end)))
    (if (string-empty-p selection)
        (call-interactively 'rgrep)
      (rgrep selection "*" default-directory))))

(global-set-key (kbd "C-c s") 'rc/rgrep-selected)

;; 11. 行尾多余空格治理：高亮显示 + C/C++/Rust/Zig 保存时自动清理
(setq-default show-trailing-whitespace t)
(dolist (hook '(term-mode-hook
                vterm-mode-hook
                compilation-mode-hook
                dired-mode-hook
                minibuffer-setup-hook))
  (add-hook hook (lambda () (setq show-trailing-whitespace nil))))

(defun rc/auto-clean-whitespace-on-save ()
  "Automatically delete trailing whitespace before saving in code buffers."
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(dolist (mode-hook '(c-mode-hook c++-mode-hook
                     c-ts-mode-hook c++-ts-mode-hook
                     rust-mode-hook zig-mode-hook))
  (add-hook mode-hook #'rc/auto-clean-whitespace-on-save))

(defun rc/c-indent-four-spaces ()
  (setq-local c-basic-offset 4))

(add-hook 'c-mode-hook #'rc/c-indent-four-spaces)
(add-hook 'c++-mode-hook #'rc/c-indent-four-spaces)
(setq c-ts-indent-offset 4)

(global-set-key (kbd "C-c w") 'delete-trailing-whitespace)

;; 12. 路径跳转（绕过 ido 干扰，支持 C/C++ 系统与本地头文件）
(defun my/get-gcc-cpp-include-dirs ()
  "Dynamically locate Arch Linux GCC C++ standard library include paths."
  (let ((base-dir "/usr/include/c++"))
    (when (file-directory-p base-dir)
      (let* ((versions (sort (directory-files base-dir nil "^[0-9]+\\(\\.[0-9]+\\)*$")
                             #'version>))
             (latest (car versions)))
        (when latest
          (let* ((ver-dir (expand-file-name latest base-dir))
                 (arch-dir (expand-file-name "x86_64-pc-linux-gnu" ver-dir))
                 (backward-dir (expand-file-name "backward" ver-dir)))
            (delq nil (list ver-dir
                            (when (file-directory-p arch-dir) arch-dir)
                            (when (file-directory-p backward-dir) backward-dir)))))))))

(use-package ffap
  :ensure nil
  :defer t
  :config
  (setq ffap-c-path
        (append '("/usr/include" "/usr/local/include")
                (my/get-gcc-cpp-include-dirs))))

(defun my/find-file-at-point ()
  "Open C/C++ header or file at point in another window."
  (interactive)
  (require 'ffap)
  (save-excursion
    (beginning-of-line)
    (if (looking-at "^[ \t]*#[ \t]*include[ \t]*[<\"\\]\\([^>\"\\]+\\)[>\"\\]")
        (let* ((header (match-string-no-properties 1))
               (search-dirs (cons default-directory ffap-c-path))
               (found (locate-file header search-dirs)))
          (if found
              (find-file-other-window found)
            (message "Header not found in ffap-c-path: %s" header)))
      (let ((guess (ffap-guesser)))
        (if (and guess (file-exists-p guess))
            (find-file-other-window guess)
          (call-interactively #'find-file-other-window))))))

(global-set-key (kbd "C-x C-g") #'my/find-file-at-point)
(global-set-key (kbd "C-c i m") 'imenu)

;; 13. Emacs Lisp 交互式表达式求值并插入结果（C-c C-j）
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-j") #'eval-print-last-sexp)))
(provide 'init-tools)
;;; init-tools.el ends here

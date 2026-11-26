;;; init-languages.el --- Major modes and compilation -*- lexical-binding: t; -*-

;; 语言主模式按文件后缀加载，不跟着配置文件一起载入。
(use-package rust-mode
  :mode "\\.rs\\'")

(use-package zig-mode
  :mode "\\.zig\\'"
  :init
  (setq zig-format-on-save nil))

(use-package go-mode
  :mode "\\.go\\'")

(use-package lua-mode
  :ensure nil
  :mode "\\.lua\\'")

(use-package typescript-mode
  :mode (("\\.ts\\'" . typescript-mode)
         ("\\.tsx\\'" . chamomile/typescript-tsx-mode))
  :config
  ;; 复用 TypeScript 模式，让 Eglot 为 .tsx 发送独立的 typescriptreact ID。
  (define-derived-mode chamomile/typescript-tsx-mode typescript-mode "TSX")
  ;; 上游在加载时插入了合并规则，移除它以免覆盖上面的 TSX 关联。
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
  :init
  (setq python-indent-offset 4))

;; 保留各 C/C++ 主模式原来的语法和项目集成，只统一缩进宽度。
(defun chamomile/c-indent-four-spaces ()
  "Use a four-column indentation step in a CC Mode buffer."
  (setq-local c-basic-offset 4))

(setq-default c-basic-offset 4)
(add-hook 'c-mode-hook #'chamomile/c-indent-four-spaces)
(add-hook 'c++-mode-hook #'chamomile/c-indent-four-spaces)
(setq c-ts-indent-offset 4)

;; 注册编译按键和输出过滤 hook，不在这里主动加载编译库。
(setq compilation-scroll-output 'first-error)
(keymap-global-set "<f5>" #'compile)
(keymap-global-set "<f6>" #'recompile)

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

(provide 'init-languages)
;;; init-languages.el ends here

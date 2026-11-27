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

(defun chamomile/makefile-present-p (directory)
  "Return non-nil if DIRECTORY contains a Makefile recognized by GNU Make."
  (seq-some (lambda (name) (file-regular-p (expand-file-name name directory)))
            '("GNUmakefile" "makefile" "Makefile")))

;; 在按 F5/F6 时才向上查找构建文件，打开源码或启动 Emacs 时不做扫描。
(defun chamomile/compile-context ()
  "Return (DIRECTORY . COMMAND) for the current local source buffer."
  (when (and buffer-file-name (not (file-remote-p buffer-file-name)))
    (let* ((directory default-directory)
           (file (shell-quote-argument
                  (concat "./" (file-name-nondirectory buffer-file-name)))))
      (cond
       ((derived-mode-p 'rust-mode 'rust-ts-mode)
        (if-let* ((root (locate-dominating-file directory "Cargo.toml")))
            (cons root "cargo build")
          (cons directory (concat "rustc --emit=metadata -o /dev/null " file))))
       ((derived-mode-p 'zig-mode 'zig-ts-mode)
        (if-let* ((root (locate-dominating-file directory "build.zig")))
            (cons root "zig build")
          (cons directory (concat "zig build-exe -fno-emit-bin " file))))
       ((derived-mode-p 'go-mode 'go-ts-mode)
        (if-let* ((root (locate-dominating-file directory "go.mod")))
            (cons root "go build ./...")
          (cons directory (concat "go build -o /dev/null " file))))
       ((derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
        (if-let* ((root (locate-dominating-file
                         directory
                         (lambda (dir)
                           (or (chamomile/makefile-present-p dir)
                               (file-regular-p (expand-file-name "CMakeLists.txt" dir)))))))
            (cond
             ((file-exists-p (expand-file-name "build/CMakeCache.txt" root))
              (cons root "cmake --build build"))
             ((file-exists-p (expand-file-name "CMakeCache.txt" root))
              (cons root "cmake --build ."))
             ((chamomile/makefile-present-p root) (cons root "make"))
             (t (cons root "cmake --build build")))
          (cons directory
                (concat (if (derived-mode-p 'c++-mode 'c++-ts-mode) "c++" "cc")
                        " -fsyntax-only " file))))))))

(defvar-local chamomile/compile-default-initialized nil
  "Non-nil once a build default has been chosen for this buffer.")

(defun chamomile/run-compile-command (command)
  "Interactively invoke COMMAND using the current buffer's build context."
  (require 'compile)
  (let* ((context (chamomile/compile-context))
         (default-directory (or (car context) default-directory)))
    (when (and buffer-file-name (not (derived-mode-p 'compilation-mode)))
      ;; 保留 .dir-locals.el、文件局部变量和之前手动输入的命令。
      ;; Zig 主模式自带的默认值可被替换，以便没有 build.zig 时仍能检查单文件。
      (unless chamomile/compile-default-initialized
        (when (or (not (local-variable-p 'compile-command))
                  (and context (derived-mode-p 'zig-mode)
                       (equal compile-command "zig build")
                       (not (assq 'compile-command dir-local-variables-alist))
                       (not (assq 'compile-command file-local-variables-alist))))
          (setq-local compile-command (or (cdr context) compile-command)))
        (setq chamomile/compile-default-initialized t)))
    (call-interactively command)))

(defun chamomile/compile ()
  "Prompt for a build command with a language-specific default."
  (interactive)
  (chamomile/run-compile-command #'compile))

(defun chamomile/recompile ()
  "Re-run the buffer's build command with the same project directory."
  (interactive)
  (chamomile/run-compile-command #'recompile))

(setq compilation-scroll-output 'first-error)
(keymap-global-set "<f5>" #'chamomile/compile)
(keymap-global-set "<f6>" #'chamomile/recompile)

(use-package ansi-color
  :ensure nil
  :hook (compilation-filter . ansi-color-compilation-filter))

(provide 'init-languages)
;;; init-languages.el ends here

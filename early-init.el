;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;;;; 启动性能

;; 启动期间减少 GC 次数，启动完成后恢复 16 MiB，避免交互时长时间停顿。
(setq gc-cons-threshold (* 100 1024 1024))

(defun chamomile/restore-gc-threshold ()
  "Restore the lower GC threshold for interactive use."
  (setq gc-cons-threshold (* 16 1024 1024)))

(add-hook 'emacs-startup-hook #'chamomile/restore-gc-threshold)

;;;; 运行数据与缓存

(defvar chamomile/cache-dir (expand-file-name "cache/" user-emacs-directory)
  "存放本机 Emacs 历史、会话状态和生成缓存。")
(unless (file-directory-p chamomile/cache-dir)
  (make-directory chamomile/cache-dir t))

;; 在这里统一设置状态文件路径；自动保存副本由 init-editor.el 配置。
(setq ido-save-directory-list-file (expand-file-name "ido.last" chamomile/cache-dir)
      save-place-file (expand-file-name "places.eld" chamomile/cache-dir)
      smex-save-file (expand-file-name "smex-items" chamomile/cache-dir)
      project-list-file (expand-file-name "projects.eld" chamomile/cache-dir)
      bookmark-default-file (expand-file-name "bookmarks.eld" chamomile/cache-dir)
      recentf-save-file (expand-file-name "recentf.eld" chamomile/cache-dir)
      savehist-file (expand-file-name "history" chamomile/cache-dir)
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" chamomile/cache-dir)
      eshell-directory-name (expand-file-name "eshell/" chamomile/cache-dir)
      ;; transient 内置于 Emacs，默认把历史写到 user-emacs-directory/transient/。
      ;; 这些变量须在 transient 首次加载（如 magit）前设置，否则会读回旧路径。
      transient-history-file (expand-file-name "transient/history.el" chamomile/cache-dir)
      transient-levels-file (expand-file-name "transient/levels.el" chamomile/cache-dir)
      transient-values-file (expand-file-name "transient/values.el" chamomile/cache-dir))

;;;; load-path 过滤（启动加速）
;; stole from https://emacs-china.org/t/emacs/30532/5
;; load-path 越长，load/require 每次查找文件都要遍历全部目录。
;; 首次命中后把“哪些目录真有这个文件”记下来，之后只探测这几个目录，
;; 并把结果持久化到 cache，跨会话复用。
(defvar chamomile/lpf-cache-file
  (expand-file-name "load-path-filter-cache.el" chamomile/cache-dir)
  "load-path 过滤器的持久化缓存文件。")

(defvar chamomile/lpf-cache
  (let ((table (and (file-readable-p chamomile/lpf-cache-file)
                    (with-temp-buffer
                      (insert-file-contents chamomile/lpf-cache-file)
                      (goto-char (point-min))
                      (condition-case nil
                          (read (current-buffer))
                        (error nil))))))
    (if (hash-table-p table)
        table
      (make-hash-table :test #'equal)))
  "load-path 过滤缓存：键为文件名，值为命中该文件的目录列表。")

;; 退出时序列化写回，供下次启动直接命中。
(add-hook 'kill-emacs-hook
          (lambda ()
            (with-temp-file chamomile/lpf-cache-file
              (insert (prin1-to-string chamomile/lpf-cache)))))

(defvar chamomile/lpf-training t
  "非 nil 时，缓存未命中则训练（填充缓存）。")

(defvar chamomile/lpf-validate t
  "非 nil 时，命中后校验条目是否仍有效，失效则删除并重新训练。")

(defun chamomile/lpf-match (path file suffixes)
  "在 PATH 中查找 FILE（依次尝试 SUFFIXES）实际存在的目录列表。"
  (catch 'found
    (dolist (suffix suffixes)
      (let ((name (concat file suffix))
            (dirs nil))
        (dolist (dir path)
          (when (file-readable-p (file-name-concat dir name))
            (push dir dirs)))
        (when dirs
          (throw 'found (nreverse dirs)))))))

(defun chamomile/lpf-train (path file suffixes)
  "把 FILE 在 PATH 中的命中目录写入缓存并返回。"
  (if (or (file-directory-p file)
          (not chamomile/lpf-training))
      path
    (let ((val (chamomile/lpf-match path file suffixes)))
      (when val
        (puthash file val chamomile/lpf-cache))
      val)))

(defun chamomile/lpf (path file suffixes)
  "load-path 过滤函数：命中时只返回少数目录，并保留完整 PATH 兜底。"
  (if-let* ((val (gethash file chamomile/lpf-cache)))
      ;; 命中：校验失效则删除缓存并重新训练。
      (progn
        (when (and chamomile/lpf-validate
                   (null (chamomile/lpf-match val file suffixes)))
          (remhash file chamomile/lpf-cache)
          (setq val (chamomile/lpf-train path file suffixes)))
        (append val path))
    ;; 未命中：训练并填充缓存，失败则回退完整 PATH。
    (or (chamomile/lpf-train path file suffixes)
        path)))

(setq load-path-filter-function #'chamomile/lpf)

;; 包激活和原生编译在读取 init.el 前就可能用到缓存，必须在这里指定路径。
(setq package-quickstart t
      package-quickstart-file (expand-file-name "package-quickstart.el" chamomile/cache-dir))
(when (and (fboundp 'startup-redirect-eln-cache) (native-comp-available-p))
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" chamomile/cache-dir)))

;;;; 首帧外观

;; 创建 GUI 窗口前隐藏菜单栏、工具栏和滚动条，避免首帧闪烁。
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; 背景保留 95% 不透明度，文字不受影响。
(add-to-list 'default-frame-alist '(alpha-background . 95))

;; 适配平铺窗口管理器（MangoWC / niri），禁止自动缩放 Frame
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t)

;;;; 启动警告

;; 屏蔽 files 类警告，例如第三方老插件缺少 lexical-binding 声明。
(add-to-list 'warning-suppress-types '(files))

(provide 'early-init)
;;; early-init.el ends here

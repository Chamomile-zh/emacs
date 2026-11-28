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
      recentf-save-file (expand-file-name "recentf.eld" chamomile/cache-dir)
      savehist-file (expand-file-name "history" chamomile/cache-dir)
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" chamomile/cache-dir)
      eshell-directory-name (expand-file-name "eshell/" chamomile/cache-dir))

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

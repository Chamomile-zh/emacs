;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;;;; 启动性能

;; 启动期间减少 GC 次数，启动完成后恢复 16 MiB，避免交互时长时间停顿。
(setq gc-cons-threshold (* 100 1024 1024))

(defun chamomile/restore-gc-threshold ()
  "Restore the lower GC threshold for interactive use."
  (setq gc-cons-threshold (* 16 1024 1024)))

(add-hook 'emacs-startup-hook #'chamomile/restore-gc-threshold)

;; 用预生成的 autoload 缓存加速启动时的包激活
(setq package-quickstart t)

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

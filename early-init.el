;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;; 启动期间调高 GC 阈值至 100MB，加速启动
(setq gc-cons-threshold (* 100 1024 1024))

;; 阻止 package.el 自动初始化
(setq package-enable-at-startup nil)

;; 在 GUI 渲染前禁用多余边框，防止启动闪烁
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; 适配平铺窗口管理器（MangoWC / niri），禁止自动缩放 Frame
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t)

;; 屏蔽第三方老插件缺少 lexical-binding 声明的启动警告
(add-to-list 'warning-suppress-types '(files))

(provide 'early-init)
;;; early-init.el ends here

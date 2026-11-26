;;; init-org.el --- Tsoding-style Org-mode Agenda & Capture -*- lexical-binding: t; -*-

;; 确保日程目录存在，避免首次调用 org-agenda 时提示目录不存在
(defvar my/org-agenda-dir (expand-file-name "~/Documents/Agenda/"))
(unless (file-directory-p my/org-agenda-dir)
  (make-directory my/org-agenda-dir t))

;; ==========================================
;; 1. 核心 Org-mode 与日程视图配置
;; ==========================================
(use-package org
  :ensure nil
  :bind (("C-x a"     . org-agenda)
         ("C-c c"     . org-capture)
         ("C-c C-x j" . org-clock-jump-to-current-clock)
         ("C-x p w"   . rc/org-kill-heading-name-save))
  :config
  (setq org-agenda-files (list my/org-agenda-dir)
        org-export-backends '(md)
        org-log-done 'time)

  ;; 自定义日程过滤视图（按 C-x a 后按 u / p / w 触发）
  (setq org-agenda-custom-commands
        '(("u" "Unscheduled" tags "+personal-SCHEDULED={.+}-DEADLINE={.+}/!+TODO"
           ((org-agenda-sorting-strategy '(priority-down))))
          ("p" "Personal" ((agenda "" ((org-agenda-tag-filter-preset (list "+personal"))))))
          ("w" "Work" ((agenda "" ((org-agenda-tag-filter-preset (list "+work"))))))))

  ;; 全局随时捕获任务模板（按 C-c c 后按 p / K 触发）
  (let ((tasks-file (expand-file-name "Tasks.org" my/org-agenda-dir)))
    (setq org-capture-templates
          `(("p" "Capture task" entry (file ,tasks-file)
             "* TODO %?\n  SCHEDULED: %t\n")
            ("K" "Cliplink capture task" entry (file ,tasks-file)
             "* TODO %(org-cliplink-capture) \n  SCHEDULED: %t\n" :empty-lines 1))))

  ;; 辅助函数 1：记录任务被推迟的次数（MOVE_COUNTER）
  (defun rc/org-increment-move-counter ()
    "Increment MOVE_COUNTER property on current Org heading."
    (interactive)
    (let* ((point (point))
           (move-counter-name "MOVE_COUNTER")
           (raw-val (org-entry-get point move-counter-name))
           (move-counter-value (1+ (string-to-number (or raw-val "0")))))
      (org-entry-put point move-counter-name
                     (number-to-string move-counter-value)))
    nil)

  ;; 辅助函数 2：提取并复制当前 Org 标题纯文本（去除 TODO 与标签）
  (defun rc/org-get-heading-name ()
    (nth 4 (org-heading-components)))

  (defun rc/org-kill-heading-name-save ()
    "Copy current Org heading text to kill-ring."
    (interactive)
    (let ((heading-name (rc/org-get-heading-name)))
      (when heading-name
        (kill-new heading-name)
        (message "Kill \"%s\"" heading-name)))))

;; ==========================================
;; 2. 剪贴板网页标题自动抓取（org-cliplink）
;; ==========================================
(use-package org-cliplink
  :after org
  :bind (("C-x p i" . org-cliplink)
         ("C-x p t" . rc/cliplink-task))
  :config
  (defun rc/cliplink-task ()
    "Insert a TODO item with title fetched from URL in clipboard."
    (interactive)
    (org-cliplink-retrieve-title
     (substring-no-properties (current-kill 0))
     (lambda (url title)
       (insert (if title
                   (concat "* TODO " title
                           "\n  [[" url "][" title "]]")
                 (concat "* TODO " url
                         "\n  [[" url "]]")))))))

(provide 'init-org)
;;; init-org.el ends here

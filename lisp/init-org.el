;;; init-org.el --- Org agenda, capture and clipboard links -*- lexical-binding: t; -*-

;;;; Org 核心与共享日程目录

(defvar chamomile/org-agenda-dir (expand-file-name "~/Documents/Agenda/")
  "Directory for Org agenda and captured tasks.")

(defun chamomile/org-ensure-agenda-directory ()
  "Create the agenda directory if it does not yet exist."
  (make-directory chamomile/org-agenda-dir t))

;; Org：编辑 .org 文件、记录完成时间并配置 Markdown 导出。
;; 打开普通 .org 文件不需要加载 Agenda、Capture 或剪贴板插件。
(use-package org
  :ensure nil
  :defer t
  :init
  (setq org-export-backends '(md)
        org-log-done 'time)
  :config
  ;; Org 核心也会查询日程文件，比如补全 refile 的目标。
  (setq org-agenda-files (list chamomile/org-agenda-dir))
  ;; C-c C-x C-l：用 latex + dvisvgm 渲染 SVG，缓存不写到笔记旁边。
  (setq org-preview-latex-default-process 'dvisvgm
        org-preview-latex-image-directory
        (expand-file-name "org-latex/" chamomile/cache-dir))
  ;; 只替换 dvisvgm 的预览导言区：latex 不支持 fontspec，本机也没有 ulem。
  ;; 保留常用数学宏包，不改变 Org 导出所用的导言区。
  (setf (alist-get 'dvisvgm org-preview-latex-process-alist)
        (plist-put (copy-sequence (alist-get 'dvisvgm org-preview-latex-process-alist))
                   :latex-header
                   "\\documentclass{article}
\\usepackage{color,amsmath,amssymb}
\\pagestyle{empty}")))

;; 用 MOVE_COUNTER 属性记录任务被推迟的次数。
(defun chamomile/org-increment-move-counter ()
  "Increment the MOVE_COUNTER property of the current Org heading."
  (interactive)
  (require 'org)
  (let* ((name "MOVE_COUNTER")
         (count (string-to-number (or (org-entry-get (point) name) "0"))))
    (org-entry-put (point) name (number-to-string (1+ count))))
  nil)

;; C-x p w：复制当前 Org 标题的纯文本，不带 TODO 状态和标签。
(defun chamomile/org-get-heading-name ()
  "Return the current Org heading without TODO keywords or tags."
  (require 'org)
  (nth 4 (org-heading-components)))

(defun chamomile/org-kill-heading-name-save ()
  "Copy the current Org heading text to the kill ring."
  (interactive)
  (when-let* ((name (chamomile/org-get-heading-name)))
    (kill-new name)
    (message "Kill \"%s\"" name)))

(keymap-global-set "C-x p w" #'chamomile/org-kill-heading-name-save)

;;;; 议程、捕获与计时

;; Org Agenda：C-x a 打开议程菜单，首次使用时创建日程目录。
(use-package org-agenda
  :ensure nil
  :bind ("C-x a" . org-agenda)
  :config
  (chamomile/org-ensure-agenda-directory)
  ;; 在议程分发菜单中按 u / p / w，分别打开未排期、个人和工作视图。
  (setq org-agenda-custom-commands
        '(("u" "Unscheduled" tags "+personal-SCHEDULED={.+}-DEADLINE={.+}/!+TODO"
           ((org-agenda-sorting-strategy '(priority-down))))
          ("p" "Personal" ((agenda "" ((org-agenda-tag-filter-preset (list "+personal"))))))
          ("w" "Work" ((agenda "" ((org-agenda-tag-filter-preset (list "+work")))))))))

;; Org Capture：C-c c 打开任务捕获菜单，任务写入日程目录中的 Tasks.org。
(use-package org-capture
  :ensure nil
  :bind ("C-c c" . org-capture)
  :config
  (chamomile/org-ensure-agenda-directory)
  (let ((tasks-file (expand-file-name "Tasks.org" chamomile/org-agenda-dir)))
    ;; p 记录普通任务；大写 K 只在展开模板时加载 org-cliplink。
    (setq org-capture-templates
          `(("p" "Capture task" entry (file ,tasks-file)
             "* TODO %?\n  SCHEDULED: %t\n")
            ("K" "Cliplink capture task" entry (file ,tasks-file)
             "* TODO %(org-cliplink-capture) \n  SCHEDULED: %t\n" :empty-lines 1)))))

;; Org Clock：C-c C-x j 跳回当前正在计时的任务。
(use-package org-clock
  :ensure nil
  :bind ("C-c C-x j" . org-clock-jump-to-current-clock))

;;;; 剪贴板链接

;; Org Cliplink：读取剪贴板 URL 和网页标题；C-x p i 插入普通 Org 链接。
;; 不用 :after org，启动后马上有键位，但按下或展开捕获模板时才加载插件。
(use-package org-cliplink
  :commands (org-cliplink-capture org-cliplink-retrieve-title)
  :bind ("C-x p i" . org-cliplink))

;; C-x p t：在光标处插入一个带网页链接的 TODO。
(defun chamomile/cliplink-task ()
  "Insert a TODO item with the title of the URL on the clipboard."
  (interactive)
  (org-cliplink-retrieve-title
   (substring-no-properties (current-kill 0))
   (lambda (url title)
     (insert (if title
                 (concat "* TODO " title "\n  [[" url "][" title "]]")
               (concat "* TODO " url "\n  [[" url "]]"))))))

(keymap-global-set "C-x p t" #'chamomile/cliplink-task)

(provide 'init-org)
;;; init-org.el ends here

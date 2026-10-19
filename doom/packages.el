;;; $DOOMDIR/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Public-only package declarations. Doom pins transitive/module packages.

;;; Terminal
(package! ghostel
  :pin "cba5fa4c0d1913eef77bcea5bab2555536adf53f")
(package! evil-ghostel
  :pin "cba5fa4c0d1913eef77bcea5bab2555536adf53f")

;;; Org presentation
(package! org-modern
  :pin "8775389d085a4ebdf77856b8f86ab4d9679fc55e")
(package! org-appear
  :pin "77d23efec5f5c25fc0798364d2b51a3ce3d8d518")
(package! mixed-pitch
  :pin "519e05f74825abf04b7d2e0e38ec040d013a125a")
(package! org-side-tree
  :pin "e8da5217ce23440a62f4a46ef60e2082b6284b28")
(package! textui
  :recipe (:host github :repo "yibie/textui")
  :pin "ce37202ec910e03008bd50472b2df1217b5f1a7e")
(package! org-table-widget
  :recipe (:host github :repo "yibie/org-table-widget")
  :pin "925ef975eca00f431f42f0bc9e2b264d95d566da")

;;; Optional private work packages
(let* ((work-enabled
        (not (member (downcase (or (getenv "DOOM_WORK_CONFIG") "auto"))
                     '("0" "false" "no" "off"))))
       (work-directory
        (file-name-as-directory
         (expand-file-name
          (or (getenv "DOOM_WORK_CONFIG_DIR") "~/.config/doom-work/"))))
       (work-packages (expand-file-name "packages.el" work-directory)))
  (when (and work-enabled (file-readable-p work-packages))
    (load work-packages nil 'nomessage)))

;;; Optional local Canvas packages
(let* ((canvas-enabled
        (member (downcase (or (getenv "DOOM_CANVAS_CONFIG") "0"))
                '("1" "true" "yes" "on")))
       (canvas-directory
        (file-name-as-directory
         (expand-file-name
          (or (getenv "DOOM_CANVAS_CONFIG_DIR") "~/.config/doom-canvas/"))))
       (canvas-packages (expand-file-name "packages.el" canvas-directory)))
  (when canvas-enabled
    (if (file-readable-p canvas-packages)
        (load canvas-packages nil 'nomessage)
      (error "Canvas package overlay enabled but missing: %s" canvas-packages))))

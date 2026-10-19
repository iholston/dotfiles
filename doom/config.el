;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Load the public configuration in dependency order.
(load! "lisp/ui")
(load! "lisp/platform")
(load! "lisp/tabs")
(load! "lisp/navigation")
(load! "lisp/org")
(load! "lisp/terminal")
(load! "lisp/windows")
(load! "lisp/workspaces")
(load! "lisp/editing")

;;; Optional private work overlay
(defconst ih-work-config-directory
  (file-name-as-directory
   (expand-file-name
    (or (getenv "DOOM_WORK_CONFIG_DIR") "~/.config/doom-work/")))
  "Directory containing the optional private Doom work overlay.")

(defun ih-work-config-enabled-p ()
  "Return non-nil unless the work overlay is explicitly disabled."
  (not (member (downcase (or (getenv "DOOM_WORK_CONFIG") "auto"))
               '("0" "false" "no" "off"))))

(let ((work-config (expand-file-name "config.el" ih-work-config-directory)))
  (when (and (ih-work-config-enabled-p)
             (file-readable-p work-config))
    (load work-config nil 'nomessage)))

;;; Optional local Canvas overlay
(defconst ih-canvas-config-directory
  (file-name-as-directory
   (expand-file-name
    (or (getenv "DOOM_CANVAS_CONFIG_DIR") "~/.config/doom-canvas/")))
  "Directory containing the optional local Canvas overlay.")

(defun ih-canvas-config-enabled-p ()
  "Return non-nil when the local Canvas overlay is explicitly enabled."
  (member (downcase (or (getenv "DOOM_CANVAS_CONFIG") "0"))
          '("1" "true" "yes" "on")))

(let ((canvas-config (expand-file-name "config.el" ih-canvas-config-directory)))
  (when (ih-canvas-config-enabled-p)
    (if (file-readable-p canvas-config)
        (load canvas-config nil 'nomessage)
      (display-warning 'doom
                       (format "Canvas overlay enabled but missing: %s"
                               canvas-config)
                       :error))))

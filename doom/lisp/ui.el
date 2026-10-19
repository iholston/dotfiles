;;; ui.el --- Theme, fonts, modeline, and visual provenance -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; Use the same primary font as WezTerm so graphical and remote terminal Emacs
;; have consistent character shapes and spacing.  TTY frames ignore `doom-font'.
(when (eq system-type 'darwin)
  (setq doom-font (font-spec :family "SF Mono" :size 16 :weight 'medium)))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; Keep any other unnamed buffers created through `evil-buffer-new' in
;; text mode instead of `fundamental-mode'.
(setq-default major-mode 'text-mode)

;;; ─── Always show the current workspace name in the modeline ─────────────
;; Doom hides the workspace name by default, and even when enabled its stock
;; `persp-name' segment is WIDTH-GATED: doom-modeline marks side-by-side splits
;; as "limited width" and drops right-side segments, so in a multi-pane layout
;; the name never appeared. Fix: recompute the name live (no width/active gate),
;; move the segment to the LEFT next to the buffer name, and rebuild the `main'
;; modeline so the new segment body is inlined (doom-modeline inlines segments).
(setq doom-modeline-persp-name t)   ; main on/off switch for the segment below
(after! doom-modeline
  (doom-modeline-def-segment window-zoom
    "Show a tmux-style marker while the current workspace window is zoomed."
    (when (and (fboundp '+window/zoomed-p)
               (+window/zoomed-p))
      (propertize " [ZOOM] "
                  'face 'warning
                  'mouse-face 'doom-modeline-highlight
                  'help-echo "Window zoomed — mouse-1 or SPC w z to restore"
                  'local-map (let ((m (make-sparse-keymap)))
                               (define-key m [mode-line mouse-1]
                                           #'+window/zoom-toggle)
                               m))))
  (doom-modeline-def-segment persp-name
    "Current workspace name — always visible (computed live), click to switch."
    (when (and doom-modeline-persp-name
               (bound-and-true-p persp-mode)
               (fboundp 'get-current-persp))
      (concat " "
              (propertize (safe-persp-name (get-current-persp))
                          'face 'doom-modeline-persp-name
                          'mouse-face 'doom-modeline-highlight
                          'help-echo "mouse-1: Pick a workspace"
                          'local-map (let ((m (make-sparse-keymap)))
                                       (define-key m [mode-line mouse-1]
                                                   #'+workspace/mouse-menu)
                                       m))
              " ")))
  (doom-modeline-def-modeline 'main
    '(eldoc bar window-state window-zoom workspace-name window-number modals matches follow
      buffer-info persp-name remote-host buffer-position word-count parrot selection-info)
    '(compilation objed-state misc-info project-name battery grip irc mu4e gnus github
      debug repl lsp minor-modes input-method indent-info buffer-encoding major-mode
      process vcs check time)))


;;; ─── Which-Key binding provenance ──────────────────────────────────────
;; Doom bindings retain their normal unmarked description. Public additions
;; use a cyan [P] badge; the private overlay uses a magenta [W] badge.
(defconst config-which-key-public-prefix "[P] ")
(defconst config-which-key-work-prefix "[W] ")

(defface config-which-key-public-face
  '((t (:inherit font-lock-function-name-face :weight semi-bold)))
  "Face for public custom Which-Key descriptions."
  :group 'which-key)

(defface config-which-key-work-face
  '((t (:inherit font-lock-keyword-face :weight bold)))
  "Face for private work Which-Key descriptions."
  :group 'which-key)

(defun config-which-key--origin-face (description)
  "Return the provenance face for unpropertized DESCRIPTION, or nil."
  (cond
   ((string-prefix-p config-which-key-public-prefix description)
    'config-which-key-public-face)
   ((string-prefix-p config-which-key-work-prefix description)
    'config-which-key-work-face)))

(defun config-which-key--style-origin-a (rendered)
  "Apply a provenance face to a Which-Key RENDERED description."
  (if (not (stringp rendered))
      rendered
    (let ((face (config-which-key--origin-face
                 (substring-no-properties rendered))))
      (if (not face)
          rendered
        (let ((styled (copy-sequence rendered)))
          (put-text-property 0 (length styled) 'face face styled)
          styled)))))

(after! which-key
  ;; Which-Key's renderer is private API. If a future release removes it, keep
  ;; the visible [P]/[W] badges and skip only the optional color treatment.
  (when (fboundp 'which-key--propertize-description)
    (advice-remove 'which-key--propertize-description
                   #'config-which-key--style-origin-a)
    (advice-add 'which-key--propertize-description :filter-return
                #'config-which-key--style-origin-a)))

(provide 'config-ui)

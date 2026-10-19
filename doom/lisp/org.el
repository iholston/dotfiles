;;; org.el --- Notes, agenda, Org behavior, and presentation -*- lexical-binding: t; -*-

;; Loaded explicitly with `load!' from config.el; this directory is not added
;; to `load-path', so this file cannot shadow Org's own org.el library.
(require 'cl-lib)
(require 'subr-x)

;;; Notes and agenda
;; Keep every note format under one canonical Obsidian vault. Doom's generic
;; `SPC n f' and `SPC n s' commands search `org-directory' recursively, so the
;; vault itself is the root. Org and Markdown files live together in their
;; topical areas rather than being separated by format.
(defcustom +notes-root
  (file-name-as-directory
   (expand-file-name
    (or (getenv "DOOM_NOTES_DIR")
        "~/Documents/Obsidian Vault/")))
  "Root directory for personal Org and Markdown notes."
  :type 'directory
  :group 'org)

(defun +notes-org-agenda-files ()
  "Return topical Org agenda files, with the task Inbox first."
  (when (file-directory-p +notes-root)
    (let* ((inbox (expand-file-name "Tasks/Inbox.org" +notes-root))
           (files
            (delq nil
                  (mapcar
                   (lambda (file)
                     (unless (string-match-p
                              "/\\(?:_Agent\\|Archive\\)/\\|/Org Sandbox\\.org\\'"
                              file)
                       file))
                   (directory-files-recursively +notes-root "\\.org\\'")))))
      (if (member inbox files)
          (cons inbox (delete inbox files))
        files))))

(defun +notes-refresh-org-agenda-files (&rest _)
  "Refresh `org-agenda-files' after Org files move or are created."
  (setq org-agenda-files (+notes-org-agenda-files)))

(setq org-directory +notes-root
      +org-capture-todo-file "Tasks/Inbox.org"
      +org-capture-notes-file "Notes/Inbox.org"
      +org-capture-journal-file "Notes/Journal/Journal.org"
      +org-capture-projects-file "Tasks/Projects.org"
      org-default-notes-file (expand-file-name "Notes/Inbox.org" +notes-root)
      org-id-locations-file (expand-file-name ".orgids" +notes-root))

(+notes-refresh-org-agenda-files)
(after! org
  ;; Doom's Org module initializes `org-agenda-files' from `org-directory'.
  ;; Reapply guarded discovery afterward so a missing root remains harmless.
  (+notes-refresh-org-agenda-files))
(advice-add 'org-agenda :before #'+notes-refresh-org-agenda-files)
(advice-add 'org-todo-list :before #'+notes-refresh-org-agenda-files)

(defun +org-agenda-pretty-todo-header ()
  "Replace Org's stock TODO header with concise Doom/Evil instructions."
  (when (and (eq org-agenda-type 'todo)
             (not (buffer-narrowed-p)))
    (let* ((inhibit-read-only t)
           (first-entry
            (text-property-not-all
             (point-min) (point-max) 'org-category nil))
           (header-end
            (if first-entry
                (save-excursion
                  (goto-char first-entry)
                  (line-beginning-position))
              (point-max)))
           (metadata
            (cl-loop
             for property in '(org-agenda-type
                               org-last-args
                               org-redo-cmd
                               org-series-cmd
                               org-series-redo-cmd
                               org-lprops)
             for value = (get-text-property (point-min) property)
             when value append (list property value)))
           (selection
            (if (and (stringp org-select-this-todo-keyword)
                     (not (string-empty-p org-select-this-todo-keyword)))
                (replace-regexp-in-string
                 "|" " · " org-select-this-todo-keyword t t)
              "ALL ACTIVE"))
           (header-start (point-min)))
      (delete-region (point-min) header-end)
      (goto-char (point-min))
      (cl-labels
          ((hint (keys label)
             (concat (propertize keys 'face 'help-key-binding)
                     (propertize (concat " " label) 'face 'shadow))))
        (insert
         (propertize (format " TODO  %s\n" selection)
                     'face 'org-agenda-structure
                     'org-agenda-structural-header t
                     'short-heading (format "ToDo: %s" selection)))
        (insert " "
                (hint "t" "state") "   "
                (hint "RET" "open") "   "
                (hint "m" "mark") "   "
                (hint "B $" "archive") "\n")
        (insert " "
                (hint "SPC u SPC n t" "filter") "   "
                (hint "0 g r" "all") "   "
                (hint "g r" "refresh") "   "
                (hint "q" "quit") "\n"))
      ;; `org-agenda-redo' reads these properties at point.  Preserve them on
      ;; the replacement header so `g r' and numeric filters work from there.
      (add-text-properties header-start (point) metadata))))

(defun +org-agenda-separate-categories ()
  "Insert a blank line before each source-file category in TODO agendas."
  (when (and (eq org-agenda-type 'todo)
             (not (buffer-narrowed-p)))
    (let ((inhibit-read-only t)
          previous-category)
      (save-excursion
        (goto-char (point-min))
        (while (< (point) (point-max))
          (let ((category
                 (get-text-property (line-beginning-position) 'org-category)))
            (when (and category
                       (or (null previous-category)
                           (not (equal category previous-category)))
                       (not (get-text-property
                             (max (point-min) (1- (line-beginning-position)))
                             '+org-agenda-category-separator)))
              (insert
               (propertize "\n" '+org-agenda-category-separator t)))
            (when category
              (setq previous-category category)))
          (forward-line 1))))))

(after! org-agenda
  ;; Keep each source file together; order within a file by urgency.
  (setf (alist-get 'todo org-agenda-sorting-strategy)
        '(category-keep urgency-down))
  (add-hook 'org-agenda-finalize-hook
            #'+org-agenda-pretty-todo-header 90)
  (add-hook 'org-agenda-finalize-hook
            #'+org-agenda-separate-categories 95))

;;; Baseline Org behavior
;;; ─── Prettier org-mode ──────────────────────────────────────────────────
(after! org
  (setq org-startup-indented t             ; indent body under its heading
        org-hide-emphasis-markers t        ; hide the *,/,_,= markup characters
        org-pretty-entities t              ; render \alpha, sub/superscripts, etc.
        org-startup-with-inline-images t)) ; show images/SVGs when a file opens

;; Support local executable Bash cells, including notebooks that explicitly SSH
;; to another host. Org ships ob-shell, so no additional package is required.
;; The helper runs immediately during a live reload and after Org on startup.
(defun +org-enable-babel-languages ()
  "Enable the Org Babel languages used by personal executable notebooks."
  (require 'ob-shell)
  (setf (alist-get 'shell org-babel-load-languages) t))
(after! org
  (+org-enable-babel-languages))
(use-package! org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (add-hook 'org-agenda-finalize-hook #'org-modern-agenda))

;; Reading-oriented Org tables: pixel-aligned borders, wrapped cells, and
;; row-by-row motion while preserving the ordinary Org source underneath.
(use-package! org-table-widget
  :after org
  :hook (org-mode . org-table-widget-mode)
  :init
  (setq org-table-widget-use-unicode-borders t
        org-table-widget-zebra-stripe t
        org-table-widget-wrap-columns t
        org-table-widget-max-width-fraction 1.0
        org-table-widget-relayout-delay 0.15
        org-table-widget-reveal-on-point nil))

(use-package! org-appear
  :hook (org-mode . org-appear-mode))      ; reveal markup when point is on it
(add-hook 'org-mode-hook #'mixed-pitch-mode) ; proportional prose, monospace code

;; Obsidian-like, clickable outline for the current Org document.
(use-package! org-side-tree
  :commands (org-side-tree org-side-tree-toggle)
  :init
  (setq org-side-tree-display-side 'right
        org-side-tree-width 35
        org-side-tree-select nil
        org-side-tree-persistent t
        outline-minor-mode-cycle t))

;;; Org presentation
;;; ─── [A0] general org display tweaks ───────────────────────────────────
(after! org
  ;; Don't show blank separator lines before a heading when its tree is folded.
  (setq org-cycle-separator-lines 0))

;;; ─── [A1] org-modern tuning ────────────────────────────────────────────
(after! org-modern
  (setq org-modern-star 'replace
        org-modern-replace-stars "◉○◈◇✳"
        org-modern-hide-stars 'leading          ; hide indent stars, keep the bullet
        org-modern-list '((?- . "–") (?+ . "•") (?* . "◦"))
        org-modern-block-fringe t               ; bracket blocks in the fringe
        org-modern-table nil                    ; OFF: its inverse-video table renderer misaligns; use plain org tables
        org-modern-todo t
        org-modern-tag nil                      ; plain inline tags, not pill buttons
        org-modern-priority t
        org-modern-timestamp t))

;;; ─── [A1b] source-block right gutter ───────────────────────────────────
;; Org's block faces use `:extend t', which intentionally paints through the
;; final text column.  Reserve one window column as page background so blocks
;; remain rectangular without touching the right edge.  This affects layout for
;; the whole Org buffer, but only full-width faces make the gutter noticeable.
(defvar +org-pretty-right-gutter-width 2
  "Minimum right margin, in columns, for pretty Org buffers.")

(defun +org-pretty--sync-right-gutter ()
  "Apply the configured right gutter to the current Org buffer and its windows."
  (setq-local right-margin-width +org-pretty-right-gutter-width)
  (dolist (window (get-buffer-window-list (current-buffer) nil t))
    (pcase-let ((`(,left . ,right) (window-margins window)))
      ;; Preserve a larger right margin installed by zen/writeroom mode.
      (set-window-margins
       window left (max +org-pretty-right-gutter-width (or right 0))))))

(add-hook 'org-mode-hook #'+org-pretty--sync-right-gutter 95)

;;; ─── [A2] heading & title typography ───────────────────────────────────
(defvar +org-pretty-prose-font "Inclusive Sans"
  "Proportional font for Org prose/headings; falls back silently if absent.")
(defvar +org-pretty-code-font "SF Mono"
  "Fixed-pitch font for Org code/tables; falls back silently if absent.")
(after! org
  (when (member +org-pretty-prose-font (font-family-list))
    (set-face-attribute 'variable-pitch nil :family +org-pretty-prose-font))
  (when (member +org-pretty-code-font (font-family-list))
    (set-face-attribute 'fixed-pitch nil :family +org-pretty-code-font))
  (custom-set-faces!
    '(org-document-title :weight bold :height 1.6)
    '(org-level-1        :weight bold :height 1.4)
    '(org-level-2        :weight bold :height 1.25)
    '(org-level-3        :weight bold :height 1.15)
    '(org-level-4        :weight semi-bold :height 1.1)
    '(org-level-5        :weight semi-bold :height 1.05)))

;; `mixed-pitch-mode' derives its fixed family from the global `default' face,
;; not from `fixed-pitch'. Override those remaps buffer-locally so Org code,
;; tables, metadata, and source-block font-lock faces use the requested font.
(after! mixed-pitch
  (defvar-local +org-pretty--code-font-cookies nil)
  (defun +org-pretty--sync-code-font ()
    "Keep fixed-pitch content in mixed-pitch Org buffers on the configured font."
    (mapc #'face-remap-remove-relative +org-pretty--code-font-cookies)
    (setq +org-pretty--code-font-cookies nil)
    (when (and (derived-mode-p 'org-mode)
               (bound-and-true-p mixed-pitch-mode)
               (member +org-pretty-code-font (font-family-list)))
      (setq +org-pretty--code-font-cookies
            (mapcar (lambda (face)
                      (face-remap-add-relative
                       face :family +org-pretty-code-font))
                    mixed-pitch-fixed-pitch-faces))))
  (add-hook 'mixed-pitch-mode-hook #'+org-pretty--sync-code-font 90))

;; ;;; ─── [A3] line spacing ─────────────────────────────────────────────────
;; (defun +org-pretty--spacing () (setq-local line-spacing 0.15))
;; (add-hook 'org-mode-hook #'+org-pretty--spacing)

;; ;;; ─── [B2] valign — pixel-aligned tables (needs package) ─────────────────
;; (when (locate-library "valign")
;;   (setq valign-fancy-bar t)
;;   (add-hook 'org-mode-hook #'valign-mode))

;;; ─── [C1] zen / writeroom tweaks (needs :ui zen) ────────────────────────
;; Center the doc without zooming and keep the mode line. ADAPT the width to
;; the screen: a comfortable fixed measure on a big external monitor, but most
;; of the width on a small laptop screen.
(defvar +zen-wide-cap 66
  "Zen column width to use on large (external-monitor) frames.")
(defvar +zen-frame-wide-threshold 150
  "Frames wider than this many columns count as a large monitor.")

(defun +zen--target-width ()
  "Frame-appropriate writeroom width: capped on big screens, wide on laptops."
  (if (> (frame-width) +zen-frame-wide-threshold)
      +zen-wide-cap
    (max 60 (- (frame-width) 8))))

(after! writeroom-mode
  (setq +zen-text-scale 0            ; no text zoom — just center at normal size
        writeroom-width +zen-wide-cap
        writeroom-mode-line t)       ; keep the mode line shown in zen
  ;; Auto-fit the column to the current frame right before zen turns on.
  (define-advice writeroom-mode (:before (&rest _) +zen--autofit-width)
    (unless (bound-and-true-p writeroom-mode)      ; only when enabling
      (setq writeroom-width (+zen--target-width))))
)

;;; ─── live A/B toggle ────────────────────────────────────────────────────
;; Flips the org-modern look (and mixed-pitch prose) on/off in the buffer.
(defvar +org-pretty--on t "Whether fancy org styling is currently active.")
(defun +org-pretty-toggle ()
  "Flip fancy⇆plain styling in the current org buffer (no reload)."
  (interactive)
  (setq +org-pretty--on (not +org-pretty--on))
  (dolist (m '(org-modern-mode mixed-pitch-mode))
    (when (fboundp m) (funcall m (if +org-pretty--on 1 -1))))
  (message "org-pretty: %s" (if +org-pretty--on "ON (fancy)" "OFF (plain)")))

;;; ─── raw / source-view toggle (Obsidian-style) ──────────────────────────
;; Reveal literal markup: emphasis markers, raw links, plain entities, real
;; stars (org-modern off), monospace. Toggle back to the pretty view.
(defvar-local +org-raw--on nil "Non-nil when this buffer shows raw markup.")
(defun +org-raw-toggle ()
  "Toggle raw markup (source) view vs. the pretty rendered view."
  (interactive)
  (setq +org-raw--on (not +org-raw--on))
  (let ((raw +org-raw--on))
    (setq-local org-hide-emphasis-markers (not raw)
                org-pretty-entities        (not raw)
                org-link-descriptive       (not raw))
    (when (fboundp 'org-modern-mode) (org-modern-mode (if raw -1 1)))
    (when (fboundp 'mixed-pitch-mode) (mixed-pitch-mode (if raw -1 1)))
    (org-restart-font-lock)
    (message "org raw view: %s" (if raw "ON (source)" "OFF (pretty)"))))

;;; Org helper commands
;; Copy only the body of the source block at point, preserving its text exactly
;; (including indentation and the final newline) but excluding block delimiters.
(defun +org/copy-src-block-body ()
  "Copy the body of the Org source block at point to the clipboard."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "This command only works in an Org buffer"))
  (unless (org-in-src-block-p)
    (user-error "Point is not in an Org source block"))
  (let (text)
    (save-mark-and-excursion
      (org-babel-mark-block)
      (setq text (buffer-substring-no-properties
                  (region-beginning) (region-end))))
    (kill-new text)
    (message "Copied source block body (%d characters)" (length text))))

;; New Org files benefit from a small, consistent document skeleton, but doing
;; this automatically would also affect generated/capture files.  Keep insertion
;; explicit and reject non-empty buffers so metadata is never duplicated.
(defun +org--default-document-title ()
  "Return a readable default title derived from the current buffer's name."
  (string-trim
   (replace-regexp-in-string
    "[-_]+" " "
    (file-name-base (or buffer-file-name (buffer-name))))))

(defun +org/insert-document-template (title)
  "Insert a standard Org document skeleton titled TITLE into an empty buffer."
  (interactive
   (list (read-string "Document title: " (+org--default-document-title))))
  (unless (derived-mode-p 'org-mode)
    (user-error "This command only works in an Org buffer"))
  (unless (string-blank-p
           (buffer-substring-no-properties (point-min) (point-max)))
    (user-error "Document template requires an empty buffer"))
  (erase-buffer)
  (insert (format "#+title: %s\n#+date: %s\n#+filetags:\n\n* Overview\n"
                  title (format-time-string "[%Y-%m-%d %a]")))
  (let ((overview-body (point)))
    (insert "\n\n* Notes\n\n* References\n")
    (goto-char overview-body))
  (when (bound-and-true-p evil-local-mode)
    (evil-insert-state)))

(provide 'config-org)

;;; windows.el --- Window dividers, splits, panning, and zoom -*- lexical-binding: t; -*-

(require 'cl-lib)

;;; ─── Mouse-drag window dividers ────────────────────────────────────────
;; Doom already enables `window-divider-mode', but its one-pixel dividers are
;; too easy for macOS to miss when a drag begins.  Use a small, reliable hit
;; target for both side-by-side and stacked splits; built-in drag behavior and
;; cursor feedback remain unchanged.
(setq window-divider-default-right-width 6
      window-divider-default-bottom-width 6
      window-divider-default-places t)
(window-divider-mode 1)

;;; ─── Splits put focus in the NEW window ─────────────────────────────────
;; Doom overrides `evil-window-split'/`evil-window-vsplit' so the new window is
;; always created below/right, then hands focus BACK to the original window
;; unless these two variables are non-nil.  Setting them keeps the cursor in the
;; freshly created split, which is Vim's behaviour: `SPC w s' moves down into
;; the new window, `SPC w v' moves right into it.
(setq evil-split-window-below t
      evil-vsplit-window-right t)


;;; ─── SPC w P → repeatable horizontal pan/scroll ──────────────────────────
;; Move the selected window's viewport instead of its divider.
;; Vim direction semantics apply:
;; h reveals earlier/left-hand columns; l reveals later/right-hand columns.
(defun +window-pan-horizontally (amount)
  "Pan the selected window horizontally by AMOUNT columns."
  (let ((current (window-hscroll)))
    (cond
     ((> amount 0)
      ;; `scroll-left' moves the displayed text left, revealing columns to the
      ;; right.  SET-MINIMUM keeps automatic hscroll from immediately undoing it.
      (scroll-left amount t))
     ((and (< amount 0) (> current 0))
      (scroll-right (min (- amount) current) t)))
    (message "Pan: column %d · h/l or </> · 0 reset · other key exits"
             (window-hscroll))))

(defun +window-pan-transient ()
  "Pan the current window horizontally with repeatable single keystrokes."
  (interactive)
  (let ((map (make-sparse-keymap))
        (step 3))
    (dolist (binding
             `(("h" . ,(lambda () (interactive) (+window-pan-horizontally (- step))))
               ("<" . ,(lambda () (interactive) (+window-pan-horizontally (- step))))
               ("l" . ,(lambda () (interactive) (+window-pan-horizontally step)))
               (">" . ,(lambda () (interactive) (+window-pan-horizontally step)))
               ("0" . +window/reset-hscroll)))
      (define-key map (car binding) (cdr binding)))
    (message "Pan: h/l or </> horizontally · 0 reset · other key exits")
    (set-transient-map map t)))

(after! evil
  ;; Doom aliases SPC w and C-w to the same map. Copy it so public
  ;; leader-only additions do not create custom Ctrl bindings.
  (define-key doom-leader-map (kbd "w") (copy-keymap evil-window-map))
  (map! :leader :desc "[P] Pan window horizontally" "w P" #'+window-pan-transient))

;;; ─── SPC w z → tmux-style window zoom (maximize / restore) ──────────────
;; First press maximizes the current window (like tmux `prefix z`); press again
;; to restore the exact previous layout. Replaces the old `SPC w m m' + `SPC w u'
;; dance. The reset-horizontal-scroll command moves to `SPC w Z' (below).
(defvar +window--zoom-configs (make-hash-table :test #'equal)
  "Saved window configurations, keyed by frame and workspace.")

(defun +window--zoom-context ()
  "Return the current frame/workspace key used for window zoom state."
  (list (selected-frame)
        (if (and (bound-and-true-p persp-mode)
                 (fboundp 'get-current-persp)
                 (get-current-persp))
            (safe-persp-name (get-current-persp))
          :no-workspace)))

(defun +window/zoomed-p ()
  "Return non-nil when the current frame/workspace is tmux-style zoomed."
  (and (gethash (+window--zoom-context) +window--zoom-configs)
       (one-window-p)))

(defun +window/zoom-toggle ()
  "Toggle a tmux-style zoom, restoring this workspace's prior layout."
  (interactive)
  (let ((context (+window--zoom-context)))
    (if (+window/zoomed-p)
        (let ((config (gethash context +window--zoom-configs)))
          (set-window-configuration config)
          (remhash context +window--zoom-configs))
      (puthash context (current-window-configuration) +window--zoom-configs)
      (delete-other-windows)))
  (force-mode-line-update t))

;;; ─── Reset a scrolled-right window to the left margin ──────
;; When a window scrolls horizontally (long lines with `truncate-lines'), you get
;; `$' truncation arrows and lose sight of the start of lines. This resets the
;; view to column 0. It also moves point to the first column first — otherwise
;; `auto-hscroll-mode' would immediately scroll back right to keep point visible.
(defun +window/reset-hscroll ()
  "Reset the current window's horizontal scroll to the left margin."
  (interactive)
  (when (and (bound-and-true-p auto-hscroll-mode) (> (current-column) 0))
    (move-to-column 0))
  (set-window-hscroll (selected-window) 0))

(map! :leader :desc "[P] Zoom window (tmux-style)" "w z" #'+window/zoom-toggle)

(provide 'config-windows)

;;; navigation.el --- Line movement, wrapping, Evil motions, and scrolling -*- lexical-binding: t; -*-

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; `relative' gives Vim-style hybrid numbers: the current line shows its
;; absolute number (via `display-line-numbers-current-absolute', on by
;; default) while all other lines show their distance from the cursor —
;; matching the `number' + `relativenumber' setup from the Neovim config.
;; Use `visual' (not `relative') so distances count VISIBLE screen lines: with
;; folded org trees / wrapped lines this keeps `20j' in sync with the number
;; shown. When nothing is folded or wrapped, `visual' == `relative'.
(setq display-line-numbers-type 'visual)

;; Emacs exposes a valid point position after a file's final newline.  That
;; position looks like an extra, unnumbered row; unlike Vim, Evil's vertical
;; motions can enter it because it is also the beginning of a line.  Keep
;; navigation on the last character-backed line without interfering with
;; commands that edit the buffer to create a new line.
(defvar-local +navigation--chars-tick-before-command nil
  "Value of `buffer-chars-modified-tick' before the current command.")

(defun +navigation--record-chars-tick-h ()
  "Record whether the next command changes buffer characters."
  (setq +navigation--chars-tick-before-command
        (buffer-chars-modified-tick)))

(defun +navigation--avoid-virtual-final-row-h ()
  "Keep non-editing navigation out of the virtual row after a final newline."
  (when (and buffer-file-name
             (bound-and-true-p evil-local-mode)
             (not (buffer-narrowed-p))
             (integerp +navigation--chars-tick-before-command)
             (= +navigation--chars-tick-before-command
                (buffer-chars-modified-tick))
             (= (point) (point-max))
             (> (point-max) (point-min))
             (eq (char-before (point-max)) ?\n))
    (goto-char (1- (point-max)))))

(add-hook 'pre-command-hook #'+navigation--record-chars-tick-h)
(add-hook 'post-command-hook #'+navigation--avoid-virtual-final-row-h)

;;; ─── Wrap everywhere, never horizontal-scroll ───────────────────────────
;; Soft-wrap long lines at word boundaries in every buffer by default, and
;; never auto-scroll sideways. This is the global version of the per-buffer
;; agent-shell fix. Any mode/buffer that genuinely needs truncation can still
;; set `truncate-lines' locally; `M-x toggle-truncate-lines' flips it on demand
;; (and horizontal scroll returns when truncation is on).
(setq-default truncate-lines nil       ; wrap instead of truncating
              word-wrap t              ; break at word boundaries, not mid-word
              auto-hscroll-mode nil)   ; never auto horizontal-scroll
(setq truncate-partial-width-windows nil) ; wrap in split (narrow) windows too

;; Escape hatch: `M-x +toggle-line-wrap' switches THIS buffer to truncation + horizontal
;; scroll (and back to wrapping). Re-enables auto-hscroll only where you ask.
(defun +toggle-line-wrap ()
  "Toggle between soft-wrap and truncate (+ horizontal scroll) in this buffer."
  (interactive)
  (setq-local truncate-lines (not truncate-lines))
  (setq-local auto-hscroll-mode truncate-lines)
  ;; `visual-line-mode' soft-wraps and OVERRIDES `truncate-lines', so truncation
  ;; won't take effect (and there's nothing to h-scroll) while it's on. Turn it
  ;; off when truncating; global `word-wrap' still soft-wraps in wrap mode.
  (when (and truncate-lines (bound-and-true-p visual-line-mode))
    (visual-line-mode -1))
  (message "This buffer: %s" (if truncate-lines "truncate + h-scroll" "wrap")))

;; Fill/unfill toggle: flatten agent-hard-wrapped prose onto one line (for
;; soft-wrap), or re-fill a long line to `fill-column'. Operates on the active
;; region, else the paragraph at point. A multi-line target is unfilled; a
;; single-line target is filled.
(defun +toggle-fill ()
  "Toggle the region or current paragraph between filled and unfilled."
  (interactive)
  (let* ((use-region (use-region-p))
         (beg (if use-region (region-beginning)
                (save-excursion (start-of-paragraph-text) (line-beginning-position))))
         (end (if use-region (region-end)
                (save-excursion (end-of-paragraph-text) (point))))
         (multiline (> (count-lines beg end) 1))
         (fill-column (if multiline most-positive-fixnum fill-column)))
    (fill-region beg end)
    (message "%s" (if multiline "unfilled → one line" "filled to column"))))

;;; ─── Keep vanilla Vim motions; disable Evil Snipe behavior ───────────────
;; Doom normally enables Snipe on `s'/`S' and overrides f/t/;/,. Keep the
;; package dormant so all of those keys retain Evil's standard Vim behavior.
(remove-hook 'doom-first-input-hook #'evil-snipe-mode)
(defun +evil-snipe-disable ()
  "Disable Evil Snipe and restore the motion map changed during its trial."
  (when (fboundp 'evil-snipe-mode)
    (evil-snipe-mode -1))
  (when (fboundp 'evil-snipe-override-mode)
    (evil-snipe-override-mode -1))
  (map! :map evil-motion-state-map
        :desc "[P] Jump to two characters" "g s s" #'evil-avy-goto-char-2
        "g s S" nil))
(if (featurep 'evil-snipe)
    (+evil-snipe-disable)
  (with-eval-after-load 'evil-snipe
    (+evil-snipe-disable)))

;; Make Doom's Avy commands label candidates in every visible window
;; on the current frame, rather than only the selected window.
(after! avy
  (setq avy-all-windows t))

;;; ─── Command-↑ / Command-↓ → scroll the view, cursor stays put ──────────
;; Like C-e / C-y (viewport scrolls, point only moves when forced off screen)
;; but several lines per press so it isn't painfully slow. Bound globally
;; (Command keys are never used for typing) so it works in every evil state.
(defvar +scroll-lines 4
  "Number of lines Command-↑ / Command-↓ scroll per press.")

(defun +scroll-view-down ()
  "Scroll the window up (text moves up) `+scroll-lines' lines, keeping point."
  (interactive)
  (evil-scroll-line-down +scroll-lines))

(defun +scroll-view-up ()
  "Scroll the window down (text moves down) `+scroll-lines' lines, keeping point."
  (interactive)
  (evil-scroll-line-up +scroll-lines))

(map! "s-<down>" #'+scroll-view-down
      "s-<up>"   #'+scroll-view-up)

(provide 'config-navigation)

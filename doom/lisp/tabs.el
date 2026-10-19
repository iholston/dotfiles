;;; tabs.el --- Workspace-aware Centaur Tabs configuration -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'seq)

(defun +tabs--next-dashboard-name ()
  "Return the first available `New Tab' dashboard buffer name."
  (let ((base "New Tab"))
    (if (not (get-buffer base))
        base
      (let ((index 1))
        (while (get-buffer (format "%s (%d)" base index))
          (setq index (1+ index)))
        (format "%s (%d)" base index)))))

;; Centaur's new-tab button normally creates an `Untitled' buffer outside
;; Doom's active workspace.  Use Doom's opening dashboard as the new-tab page,
;; register each clone with this perspective, and keep the tab strip visible.
(defun +tabs--open-dashboard ()
  "Open a fresh Doom dashboard tab in the current workspace."
  (interactive)
  ;; Render the canonical dashboard in this window first so its shared text is
  ;; sized correctly, then give the tab its own buffer identity.  Indirect
  ;; clones preserve Doom's buttons and mode while allowing repeated new tabs.
  (+dashboard/open (selected-frame))
  (let* ((dashboard (doom-fallback-buffer))
         (tab-name (+tabs--next-dashboard-name))
         (tab (with-current-buffer dashboard
                (clone-indirect-buffer tab-name nil t))))
    (when (bound-and-true-p persp-mode)
      (persp-add-buffer tab (get-current-persp) nil nil))
    (switch-to-buffer tab)
    (when (bound-and-true-p centaur-tabs-local-mode)
      (centaur-tabs-local-mode -1))))

(defun +tabs-buffer-groups ()
  "Keep every Centaur tab in the current Doom workspace together."
  (let ((workspace (and (bound-and-true-p persp-mode)
                        (get-current-persp))))
    (list (if workspace
              (format "Workspace: %s" (safe-persp-name workspace))
            "Common"))))

(defun +tabs--buffer-workspaces (&optional buffer)
  "Return the Doom workspaces that contain BUFFER.

Unlike `persp-other-persps-with-buffer-except-nil', this ignores persp-mode's
special `none' entry and returns only real perspective objects."
  (when (bound-and-true-p persp-mode)
    (let ((buffer (or buffer (current-buffer)))
          workspaces)
      (maphash (lambda (_name workspace)
                 (when (and (perspective-p workspace)
                            (memq buffer (persp-buffers workspace)))
                   (push workspace workspaces)))
               *persp-hash*)
      (nreverse workspaces))))

(defun +tabs--keep-buffer-in-origin-workspace-a (fn &rest args)
  "Prevent Doom's automatic registration from making tabs bleed workspaces.

A buffer is owned by the first Doom workspace that registers it.  Merely
displaying it from another workspace does not import it there; explicit calls
to `persp-add-buffer' still work when sharing is intentional."
  (let* ((buffer (current-buffer))
         (workspace (and (bound-and-true-p persp-mode)
                         (get-current-persp)))
         (owners (+tabs--buffer-workspaces buffer)))
    (unless (and workspace owners (not (memq workspace owners)))
      (apply fn args))))

(defun +tabs--remove-buffer-from-workspace (buffer workspace)
  "Remove BUFFER from WORKSPACE without killing the buffer."
  (let ((persp-autokill-buffer-on-remove nil))
    (persp-remove-buffer buffer workspace nil nil nil nil))
  (when (fboundp 'centaur-tabs-buffer-update-groups)
    (centaur-tabs-buffer-update-groups)
    (centaur-tabs-display-update)))

(defun +tabs/remove-current-buffer-from-workspace ()
  "Remove the current buffer from this workspace without killing it elsewhere."
  (interactive)
  (let ((buffer (current-buffer))
        (workspace (and (bound-and-true-p persp-mode)
                        (get-current-persp))))
    (unless (and workspace (memq buffer (persp-buffers workspace)))
      (user-error "Current buffer is not registered in a Doom workspace"))
    (+tabs--remove-buffer-from-workspace buffer workspace)
    (message "Removed %s from workspace %s (buffer is still alive)"
             (buffer-name buffer) (safe-persp-name workspace))))

(defun +tabs--close-buffer-in-workspace (tab)
  "Close TAB locally when shared, otherwise kill its buffer normally."
  (let* ((buffer (centaur-tabs-tab-value tab))
         (workspace (and (bound-and-true-p persp-mode)
                         (get-current-persp)))
         (owners (+tabs--buffer-workspaces buffer)))
    (if (and workspace
             (memq workspace owners)
             (delq workspace (copy-sequence owners)))
        (+tabs--remove-buffer-from-workspace buffer workspace)
      (kill-buffer buffer)
      (centaur-tabs-buffer-update-groups)
      (centaur-tabs-display-update))))

(defconst +tabs--order-parameter '+tabs-order-v1
  "Perspective parameter holding the stable Centaur buffer-name order.")

(defun +tabs--workspace-group-name (workspace)
  "Return the Centaur group name belonging to WORKSPACE."
  (format "Workspace: %s" (safe-persp-name workspace)))

(defun +tabs--workspace-tabset (workspace)
  "Return WORKSPACE's live Centaur tabset, or nil."
  (and workspace
       (bound-and-true-p centaur-tabs-tabsets)
       (centaur-tabs-get-tabset (+tabs--workspace-group-name workspace))))

(defun +tabs--workspace-eligible-buffers (workspace)
  "Return live, non-temporary buffers eligible for WORKSPACE tabs."
  (seq-filter (lambda (buffer)
                (and (buffer-live-p buffer)
                     (not (doom-temp-buffer-p buffer))))
              (safe-persp-buffers workspace)))

(defun +tabs--stored-order (workspace)
  "Return WORKSPACE's stored tab names, or the symbol `missing'."
  (let ((state (persp-parameter +tabs--order-parameter workspace)))
    (if (and (listp state) (eql (plist-get state :version) 1))
        (copy-sequence (plist-get state :names))
      'missing)))

(defun +tabs--save-workspace-order (workspace names)
  "Persist ordered buffer NAMES in WORKSPACE."
  (set-persp-parameter
   +tabs--order-parameter
   (list :version 1 :names (copy-sequence names))
   workspace)
  names)

(defun +tabs--tabset-buffers (tabset)
  "Return TABSET's live buffers in visual order."
  (when tabset
    (delq nil
          (mapcar (lambda (tab)
                    (let ((buffer (centaur-tabs-tab-value tab)))
                      (and (buffer-live-p buffer) buffer)))
                  (centaur-tabs-tabs tabset)))))

(defun +tabs--reconcile-workspace-order (workspace)
  "Return and persist WORKSPACE order after add/remove reconciliation.

Existing names retain their exact stored positions.  Removed buffers disappear,
and newly eligible buffers append in creation order.  With no stored state,
seed from the current visual tabset when available."
  (let* ((eligible (+tabs--workspace-eligible-buffers workspace))
         (eligible-names (mapcar #'buffer-name eligible))
         (stored (+tabs--stored-order workspace))
         (seed
          (if (eq stored 'missing)
              (let* ((tabset (+tabs--workspace-tabset workspace))
                     (visible
                      (seq-filter
                       (lambda (name) (member name eligible-names))
                       (mapcar #'buffer-name (+tabs--tabset-buffers tabset)))))
                ;; `persp-add-buffer' pushes, so reverse only the missing names
                ;; to append simultaneous additions in creation order.
                (append visible
                        (seq-filter (lambda (name) (not (member name visible)))
                                    (reverse eligible-names))))
            stored))
         (kept (seq-filter (lambda (name) (member name eligible-names)) seed))
         (added (seq-filter (lambda (name) (not (member name kept)))
                            (reverse eligible-names)))
         (names (append kept added)))
    (+tabs--save-workspace-order workspace names)
    names))

(defun +tabs--apply-workspace-order (&optional workspace)
  "Apply WORKSPACE's reconciled order to its live Centaur tabset."
  (let* ((workspace (or workspace
                        (and (bound-and-true-p persp-mode)
                             (get-current-persp))))
         (tabset (+tabs--workspace-tabset workspace)))
    (when (and workspace tabset)
      (let* ((names (+tabs--reconcile-workspace-order workspace))
             (tabs
              (delq nil
                    (mapcar (lambda (name)
                              (when-let ((buffer (get-buffer name)))
                                (centaur-tabs-get-tab buffer tabset)))
                            names))))
        (unless (equal tabs (centaur-tabs-tabs tabset))
          (set tabset tabs)
          (put tabset 'start
               (min (centaur-tabs-start tabset)
                    (max 0 (1- (length tabs)))))
          (centaur-tabs-set-template tabset nil))
        tabs))))

(defun +tabs--capture-workspace-order (&optional workspace)
  "Capture WORKSPACE's exact live visual tab order, when available."
  (let* ((workspace (or workspace
                        (and (bound-and-true-p persp-mode)
                             (get-current-persp))))
         (tabset (+tabs--workspace-tabset workspace)))
    (when (and workspace tabset)
      (let* ((eligible (+tabs--workspace-eligible-buffers workspace))
             (visual (seq-filter (lambda (buffer) (memq buffer eligible))
                                 (+tabs--tabset-buffers tabset)))
             (missing (seq-filter (lambda (buffer) (not (memq buffer visual)))
                                  (reverse eligible))))
        (+tabs--save-workspace-order
         workspace (mapcar #'buffer-name (append visual missing)))))))

(defun +tabs--capture-current-order-h (_scope)
  "Capture the active workspace order immediately before deactivation."
  (+tabs--capture-workspace-order))

(defun +tabs--restore-current-order-h (_scope)
  "Rebuild and restore the newly active workspace's stable order."
  (when (bound-and-true-p centaur-tabs-mode)
    (centaur-tabs-buffer-update-groups)
    (centaur-tabs-display-update)))

(defun +tabs--stabilize-after-group-update-a (&rest _)
  "Restore stable order after Centaur's stock tabset reconciliation."
  (+tabs--apply-workspace-order))

(defun +tabs--move-current-tab (direction)
  "Move the current tab one slot in DIRECTION and persist the order."
  (let* ((workspace (and (bound-and-true-p persp-mode)
                         (get-current-persp)))
         (tabset (+tabs--workspace-tabset workspace))
         (tabs (and tabset (copy-sequence (centaur-tabs-tabs tabset))))
         (current (and tabset (centaur-tabs-get-tab (current-buffer) tabset)))
         (index (and current (cl-position current tabs :test #'eq)))
         (target (and index (+ index direction))))
    (unless index
      (user-error "Current buffer has no tab in this workspace"))
    (unless (and (>= target 0) (< target (length tabs)))
      (user-error "No tab to the %s" (if (< direction 0) "left" "right")))
    (cl-rotatef (nth index tabs) (nth target tabs))
    (set tabset tabs)
    (+tabs--save-workspace-order
     workspace
     (mapcar (lambda (tab) (buffer-name (centaur-tabs-tab-value tab))) tabs))
    (centaur-tabs-set-template tabset nil)
    (centaur-tabs-display-update)))

(defun +tabs/move-current-left ()
  "Move the current workspace tab one position left."
  (interactive)
  (+tabs--move-current-tab -1))

(defun +tabs/move-current-right ()
  "Move the current workspace tab one position right."
  (interactive)
  (+tabs--move-current-tab 1))

(after! persp-mode
  ;; Doom normally adds every displayed buffer to the active perspective,
  ;; which silently makes a buffer (and therefore its tab) workspace-shared.
  (advice-remove '+workspaces-add-current-buffer-h
                 #'+tabs--keep-buffer-in-origin-workspace-a)
  (advice-add '+workspaces-add-current-buffer-h :around
              #'+tabs--keep-buffer-in-origin-workspace-a)
  (remove-hook 'persp-before-deactivate-functions
               #'+tabs--capture-current-order-h)
  (add-hook 'persp-before-deactivate-functions
            #'+tabs--capture-current-order-h)
  (remove-hook 'persp-activated-functions #'+tabs--restore-current-order-h)
  (add-hook 'persp-activated-functions #'+tabs--restore-current-order-h))

(after! centaur-tabs
  ;; Seed the currently visible workspace before installing rebuild advice.
  (+tabs--capture-workspace-order)
  (advice-remove 'centaur-tabs-buffer-update-groups
                 #'+tabs--stabilize-after-group-update-a)
  (advice-add 'centaur-tabs-buffer-update-groups :after
              #'+tabs--stabilize-after-group-update-a)
  ;; The close button should not kill a buffer that belongs to another
  ;; workspace; detach only this workspace's tab in that case.
  (advice-remove 'centaur-tabs-buffer-close-tab
                 #'+tabs--close-buffer-in-workspace)
  (advice-add 'centaur-tabs-buffer-close-tab :override
              #'+tabs--close-buffer-in-workspace)
  (map! :leader
        :desc "[P] Remove buffer from workspace" "b D"
        #'+tabs/remove-current-buffer-from-workspace
        :desc "[P] Move buffer tab left"  "b H" #'+tabs/move-current-left
        :desc "[P] Move buffer tab right" "b L" #'+tabs/move-current-right))

(defun +tabs--tab-at-mouse-position (position)
  "Return Centaur's tab object at mouse POSITION, or nil."
  (when-let ((string-position (posn-string position)))
    (get-text-property (cdr string-position) 'centaur-tabs-tab
                       (car string-position))))

(defun +tabs--reorder-tab (source target)
  "Move Centaur tab SOURCE to TARGET's position in their shared tabset."
  (let* ((tabset (centaur-tabs-tab-tabset source))
         (tabs (and (eq tabset (centaur-tabs-tab-tabset target))
                    (centaur-tabs-tabs tabset)))
         (source-index (cl-position source tabs :test #'eq))
         (target-index (cl-position target tabs :test #'eq)))
    (when (and source-index target-index (/= source-index target-index))
      (let* ((without-source (delq source (copy-sequence tabs)))
             (reordered
              (append (cl-subseq without-source 0 target-index)
                      (list source)
                      (nthcdr target-index without-source))))
        (set tabset reordered)
        (+tabs--capture-workspace-order)
        (centaur-tabs-set-template tabset nil)
        (centaur-tabs-display-update)
        t))))

(defun +tabs/drag-to-reorder (event)
  "Reorder a Centaur tab by dragging it onto another tab with EVENT."
  (interactive "e")
  (let* ((start (event-start event))
         (end (event-end event))
         (source-window (posn-window start))
         (target-window (posn-window end))
         (source (+tabs--tab-at-mouse-position start))
         (target (+tabs--tab-at-mouse-position end)))
    (when (and (window-live-p source-window)
               (eq source-window target-window)
               source target)
      (with-selected-window source-window
        (+tabs--reorder-tab source target)))))

(defun +tabs-apply-theme-colors-h ()
  "Give Centaur's strip and inactive tabs clear Doom palette contrast."
  (let ((bar-background (or (doom-color 'base0)
                            (face-background 'default nil t)
                            'unspecified))
        (inactive-background (or (doom-color 'base4)
                                 (face-background 'mode-line-inactive nil t)
                                 'unspecified))
        (inactive-foreground (or (doom-color 'base7)
                                 (face-foreground 'mode-line-inactive nil t)
                                 'unspecified)))
    (setq centaur-tabs-background-color bar-background
          centaur-tabs-style-left ""
          centaur-tabs-style-right ""
          ;; Preserve each Nerd icon's normal color instead of forcing inactive
          ;; icons to the low-contrast mode-line-inactive foreground.
          centaur-tabs-gray-out-icons nil)
    (set-face-attribute 'centaur-tabs-default nil
                        :foreground bar-background
                        :background bar-background)
    ;; Keep Centaur's built-in mouse regions for click targeting, but make
    ;; their hover faces visually inert.
    (dolist (face '(centaur-tabs-name-mouse-face
                    centaur-tabs-close-mouse-face))
      (set-face-attribute face nil
                          :inherit nil
                          :foreground 'unspecified
                          :background 'unspecified
                          :box nil
                          :underline nil
                          :overline nil))
    ;; Modus gives inactive tab faces a contrasting box.  Centaur applies those
    ;; faces to the margin, label, close button, and marker separately, so the
    ;; box repeats as bars and an outlined square between tabs.  Strip only
    ;; those decorations; retain the theme-aware foreground/background fills.
    (dolist (face '(centaur-tabs-selected
                    centaur-tabs-selected-modified
                    centaur-tabs-close-selected
                    centaur-tabs-modified-marker-selected
                    centaur-tabs-unselected
                    centaur-tabs-unselected-modified
                    centaur-tabs-close-unselected
                    centaur-tabs-modified-marker-unselected))
      (set-face-attribute face nil
                          :box nil
                          :underline nil
                          :overline nil))
    (dolist (face '(centaur-tabs-unselected
                    centaur-tabs-unselected-modified
                    centaur-tabs-close-unselected
                    centaur-tabs-modified-marker-unselected))
      (set-face-attribute face nil :background inactive-background))
    (dolist (face '(centaur-tabs-unselected
                    centaur-tabs-unselected-modified
                    centaur-tabs-close-unselected))
      (set-face-attribute face nil :foreground inactive-foreground))
    (when (and (bound-and-true-p centaur-tabs-mode)
               (vectorp centaur-tabs-tabsets))
      (centaur-tabs-map-tabsets
       (lambda (tabset)
         (when (symbolp tabset)
           (centaur-tabs-set-template tabset nil))))
      (centaur-tabs-display-update))))

(after! centaur-tabs
  ;; Keep Centaur's conventional browser layout: tabs first, then +.  New tabs
  ;; appear immediately before +, so the control moves right with the strip.
  ;; macOS emits double/triple events for rapid clicks, and this trackpad has
  ;; also produced mouse-2 events.  Every click over + should be harmlessly
  ;; interpreted as another new tab.
  (dolist (event '(mouse-1 mouse-2
                   double-mouse-1 triple-mouse-1
                   double-mouse-2 triple-mouse-2))
    (define-key centaur-tabs-new-tab-map
                (vector centaur-tabs-display-line event)
                #'centaur-tabs-new-tab--button))
  ;; Labels only select.  Never treat a middle or repeated click on a label as
  ;; a close request.
  (dolist (event '(mouse-1 mouse-2
                   double-mouse-1 triple-mouse-1
                   double-mouse-2 triple-mouse-2))
    (define-key centaur-tabs-default-map
                (vector centaur-tabs-display-line event)
                #'centaur-tabs-do-select))
  ;; Closing requires one deliberate primary click directly on ×.  Ignore
  ;; repeated/middle events so a rapid click cannot cascade into another tab.
  (define-key centaur-tabs-close-map
              (vector centaur-tabs-display-line 'mouse-1)
              #'centaur-tabs-do-close)
  (dolist (event '(mouse-2
                   double-mouse-1 triple-mouse-1
                   double-mouse-2 triple-mouse-2))
    (define-key centaur-tabs-close-map
                (vector centaur-tabs-display-line event)
                #'ignore))
  ;; Doom hides Centaur's header line on its dashboard by default.  Keep it
  ;; visible because the dashboard is our new-tab page.
  (remove-hook '+dashboard-mode-hook
               #'+tabs-disable-centaur-tabs-mode-maybe-h)
  (remove-hook '+doom-dashboard-mode-hook
               #'+tabs-disable-centaur-tabs-mode-maybe-h)
  ;; Make config reloads idempotent and remove the previous Untitled override.
  (advice-remove 'centaur-tabs--create-new-empty-buffer
                 #'+tabs--create-new-empty-buffer)
  (advice-remove 'centaur-tabs--create-new-empty-buffer
                 #'+tabs--open-dashboard)
  (advice-add 'centaur-tabs--create-new-empty-buffer :override
              #'+tabs--open-dashboard)
  ;; `+tabs-buffer-list' already scopes tabs to the active perspective; assign
  ;; those buffers one shared group so mode/project heuristics cannot split the
  ;; visual strip inside a Doom workspace.
  (setq centaur-tabs-buffer-groups-function #'+tabs-buffer-groups
        centaur-tabs-right-edge-margin " "
        centaur-tabs-style "box"
        centaur-tabs-set-bar nil)
  (+tabs-apply-theme-colors-h)
  (add-hook 'doom-load-theme-hook #'+tabs-apply-theme-colors-h)
  ;; Normal clicks select tabs; dragging one label onto another reorders it.
  (define-key centaur-tabs-default-map
              (vector centaur-tabs-display-line 'drag-mouse-1)
              #'+tabs/drag-to-reorder)
  (map! :leader
        :desc "[P] Previous tab"      "b h" #'centaur-tabs-backward
        :desc "[P] Next tab"          "b l" #'centaur-tabs-forward
        :desc "[P] New dashboard tab" "b N" #'+tabs--open-dashboard))

;; Doom's tabs module normally waits for the first file-visiting buffer before
;; enabling Centaur Tabs.  Restored Ghostel-only sessions may never visit a
;; file, so enable the global tab strip as soon as normal startup completes.
(defun +tabs-enable-centaur-tabs-h ()
  "Enable Centaur Tabs without toggle semantics."
  (centaur-tabs-mode 1))

(remove-hook 'doom-first-file-hook #'centaur-tabs-mode)
(add-hook 'doom-after-init-hook #'+tabs-enable-centaur-tabs-h)

(provide 'config-tabs)

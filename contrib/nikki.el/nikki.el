;;; nikki.el --- A simple nikki editing mode
;; Copyright (C) 2001 Keisuke Nishida <kxn30@po.cwru.edu>

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Setup:

;; (autoload 'nikki "nikki" nil t)
;; (autoload 'nikki-mode "nikki" nil t)
;; 
;; (setq nikki-directory "~/diary")
;; (setq nikki-hns-directory "~/diary/hns")
;; (setq nikki-url "http://server/~user/diary/")

;;; Code:

(defvar nikki-directory "~/diary")
(defvar nikki-hns-directory "~/diary/hns")

(defvar nikki-url
  (concat "http://" (system-name) "/~" (user-login-name) "/diary/"))

(defvar nikki-mode-map nil)
(unless nikki-mode-map
  (setq nikki-mode-map (make-sparse-keymap))
  (define-key nikki-mode-map "\C-c\C-m" 'nikki-update-time)
  (define-key nikki-mode-map "\C-c\C-h" 'nikki-view-hnf)
  (define-key nikki-mode-map "\C-c\C-v" 'nikki-view-url))

(defun nikki-mode ()
  (interactive)
  (outline-mode)
  (set-keymap-parent nikki-mode-map outline-mode-map)
  (use-local-map nikki-mode-map)
  (setq mode-name "Nikki")
  (add-hook 'local-write-file-hooks 'nikki-to-hnf))


;;;
;;; Interactive commands
;;;

(defun nikki ()
  (interactive)
  (let* ((file (nikki-outline-file))
	 (dir (file-name-directory file)))
    (if (not (file-directory-p dir))
	(make-directory dir))
    (find-file file)
    (when (= (buffer-size) 0)
      (insert (format-time-string "%Y-%m-%d"))
      (indent-to-column 56)
      (insert "-*- nikki -*-\n\n")
      (set-buffer-modified-p nil))
    (nikki-mode)))

(defun nikki-outline-file ()
  (let ((file (format-time-string "%Y%m/d%Y%m%d.txt"  (current-time))))
    (expand-file-name file nikki-directory)))

(defun nikki-nhf-file ()
  (let ((name (file-name-nondirectory
	       (file-name-sans-extension buffer-file-name)))
	(dir (format-time-string "%Y/" (current-time))))
    (expand-file-name (concat dir name ".hnf") nikki-hns-directory)))

(defun nikki-update-time ()
  (interactive)
  (save-excursion
    (when (re-search-backward "^\\* " nil t)
      (end-of-line)
      (when (eq (char-before) ?\))
	(backward-sexp)
	(if (looking-at "([0-9]+:[0-9]+)")
	    (kill-line)
	  (forward-sexp)))
      (if (not (eq (char-before) ? )) (insert " "))
      (insert (format-time-string "(%H:%M)")))))

(defun nikki-view-hnf ()
  (interactive)
  (find-file (nikki-nhf-file)))

(defun nikki-view-url ()
  (interactive)
  (browse-url nikki-url))


;;;
;;; Convert outline to hnf
;;;

(defun nikki-to-hnf ()
  (let ((str (buffer-string))
	(hnf (nikki-nhf-file)))
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (forward-line 2)
      (delete-region (point-min) (point))
      (nikki-convert)
      (set-buffer-file-coding-system 'euc-jp)
      (write-file hnf))))

(defun nikki-convert ()
  (insert "OK\n\n")
  (nikki-convert-structure)
  (nikki-convert-inline))

(defun nikki-convert-structure ()
  (while (not (eobp))
    (cond
     ((looking-at "\\*\\*") (replace-match "SUB") (forward-line 1))
     ((looking-at "\\*") (replace-match "NEW") (forward-line 1))
     ((looking-at "  ") (nikki-convert-pre))
     ((looking-at ".") (nikki-convert-paragraph))
     (t (forward-line 1)))))

(defun nikki-convert-pre ()
  (insert "PRE\n")
  (if (re-search-forward "^[^ \t\n]" nil 1)
      (goto-char (match-beginning 0)))
  (re-search-backward "^[^\n]")
  (end-of-line)
  (insert "\n/PRE"))

(defun nikki-convert-paragraph ()
  (insert "P\n")
  (forward-paragraph)
  (insert "/P\n"))

(defun nikki-convert-inline ()
  ;; convert links
  (goto-char (point-min))
  (while (re-search-forward " *@<\\([^>]*\\)>" nil t)
    (let ((url (match-string 1)))
      (replace-match "")
      (cond
       ((save-excursion
	  (and (re-search-backward "[^ \t\n]" nil t)
	       (eq (char-after) ?\})))
	(re-search-backward "{\\([^\}]*\\)}")
	(replace-match (concat "\nLINK " url " " (match-string 1) "\n")))
       ((save-excursion (beginning-of-line) (looking-at "NEW\\|SUB"))
	(beginning-of-line)
	(insert "L")
	(forward-word 1)
	(insert " " url)))))
  ;; convert footnotes
  (goto-char (point-min))
  (while (search-forward "{{" nil t)
    (replace-match "\nFN\n")
    (if (search-forward "}}" nil t)
	(replace-match "\n/FN\n")
      (error "footnote not closed"))))

;;; nikki.el ends here

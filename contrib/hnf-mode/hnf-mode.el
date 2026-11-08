;;; hnf-mode.el --- major mode for editing hnf.

;; Copyright (C) 1998-2001 by Akihiro Arisawa

;; Author: Akihiro Arisawa <ari@nijino.com>
;; Version: $Id: hnf-mode.el,v 3.37 2002/03/29 12:55:29 ari Exp $
;; Keywords: hnf nikki hns

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(defconst hnf-mode-version "2.5")

(eval-when-compile (require 'cl))
(require 'poe)
(require 'pcustom)

(defgroup hnf nil
  "Hyper Nikki File"
  :group 'hypermedia)

(defcustom hnf-diary-dir "~/diary"
  "Name of the hns diary directory."
  :group 'hnf
  :type 'directory)

(defcustom hnf-html-dir "~/public_html/diary"
  "Name of the hns web directory."
  :group 'hnf
  :type 'directory)

(defcustom hnf-hns-program (concat hnf-html-dir "/index.cgi")
  "Program name of the hns."
  :group 'hnf
  :type 'file)

(defcustom hnf-document-root "/usr/local/apache/htdocs"
  "The directory of server's DocumentRoot."
  :group 'hnf
  :type 'directory)

(defcustom hnf-diary-year-directory-flag t
  "Non-nil means hnf file is put at yearly directory.
If this flag is nil, hnf file is put at directly under `hnf-diary-directory'."
  :group 'hnf
  :type 'boolean)

(defcustom hnf-diary-url (concat "http://" (system-name) "/"
				 "~" (user-login-name) "/diary/")
  "The URL of diary."
  :group 'hnf
  :type 'string)

(defcustom hnf-index-name-list '("index.html" "index.shtml" "index.phtml")
  "File name as index."
  :group 'hnf
  :type 'list)

(defcustom hnf-mode-hook nil
  "Hook colled by `hnf-mode'."
  :group 'hnf
  :type 'hook)

(defcustom hnf-mode-load-hook nil
  "Hook called when `hnf-mode' is loaded."
  :group 'hnf
  :type 'hook)

(defcustom hnf-initial-function nil
  "Functions called when visit new file."
  :group 'hnf
  :type 'function)

(defcustom hnf-variable nil
  "Variable name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-rlink nil
  "RLINK name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-cat nil
  "Category name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-group nil
  "Group name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-class nil
  "Class name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-mark nil
  "MARK name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-alias nil
  "ALIAS name used in hnf."
  :group 'hnf
  :type 'list)

(defcustom hnf-font-lock-flag t
  "Non-nil means font-lock is used."
  :group 'hnf
  :type 'boolean)

(defcustom hnf-outline-flag t
  "Non-nil means outline-minor-mode is used."
  :group 'hnf
  :type 'boolean)

(defcustom hnf-complete-command-insert-space-flag t
  "Non-nil means insert space character after complete command."
  :group 'hnf
  :type 'boolean)

(defcustom hnf-complete-command-insert-newline-function 'hnf-newline
  "Functions call after complete command taking no argument."
  :group 'hnf
  :type 'function)

(defcustom hnf-time-format "(%H:%M)"
  "Format for `hnf-insert-time'.  See also `format-time-string'."
  :group 'hnf
  :type 'string)

(defcustom hnf-time-regexp "([0-9][0-9]:[0-9][0-9])"
  "Regexp for string inserted by `hnf-insert-time'."
  :group 'hnf
  :type 'regexp)

(defcustom hnf-namazu-index-dir (concat hnf-diary-dir "/namazu/index")
  "Name of the directory put index of namazu."
  :group 'hnf
  :type 'directory)

(defcustom hnf-tab-command 'tab-to-tab-stop
  "Functions called in `hnf-tab-complete' when not completed/expanded."
  :group 'hnf
  :type 'function)

(defcustom hnf-new-link-name-format "?%Y%m%h&to=%Y%m%d%N#%Y%m%d%N"
  "The format specification of NEW line link name in `hnf-get-link'.

%Y is the year.
%m is the month.
%d is the day.
%h is the day-hi. (The day divided by 10.)
%a is the day-abc. (1st - 10th is \"a\", 11th - 20th is \"b\", other is \"c\".)
%N is the new count.
%S is the sub count.
%% is \"%\".

For example, hns-1.03pl0 or earlyer format is \"?%Y%m%h#%Y%m%d%N\",
hns-2.10 or later format is \"?%Y%m%a&to=%Y%m%d%N#%Y%m%d%N\",
static format is \"%Y%m.html#%Y%m%d%N\".")

(defcustom hnf-sub-link-name-format "?%Y%m%d%N&to=%Y%m%d%NS%S#%Y%m%d%NS%S"
  "The format specification of SUB line link name in `hnf-get-link'.
See the documentation of the `hnf-new-link-name-format' for more detail.

For example, hns-1.03pl0 or earlyer format is \"?%Y%m%h#%Y%m%d%NS%S\",
hns-2.10 or later format is \"?%Y%m%a&to=%Y%m%d%NS%S#%Y%m%d%NS%S\",
static format is \"%Y%m.html#%Y%m%d%NS%S\".")

(defcustom hnf-hour-not-today 0
  "Till the specified hour, considered as the day before.
Set integer from 0 to 23.

eg. If you specify 6, from 0:00 to 5:59 is considered as the day before,
    and you type M-x hnf then open yesterday hnf. Also, you type
    M-x hnf-insert-time then inserte like \"25:00\"."
  :group 'hnf
  :type 'integer)

(defcustom hnf-browse-url-browser-function browse-url-browser-function
  "Function to display the diary in a WWW browser.
See also `browse-url-browser-function'."
  :group 'hnf
  :type 'function)

(defface hnf-cat-face
  '((((class color) (background light)) (:foreground "Purple" :bold t))
    (((class color) (background dark)) (:foreground "Cyan" :bold t))
    (t (:bold t)))
  "Face for CAT line in hnf."
  :group 'hnf)
(defface hnf-new-face
  '((((class color) (background light)) (:foreground "Purple" :bold t))
    (((class color) (background dark)) (:foreground "Cyan" :bold t))
    (t (:bold t)))
  "Face for NEW line in hnf."
  :group 'hnf)
(defface hnf-sub-face
  '((((class color) (background light)) (:foreground "Purple"))
    (((class color) (background dark)) (:foreground "Cyan"))
    (t ()))
  "Face for SUB line in hnf."
  :group 'hnf)
(defface hnf-link-face
  '((((class color) (background light)) (:foreground "Blue"))
    (((class color) (background dark)) (:foreground "LightSkyBlue"))
    (t ()))
  "Face for link in hnf."
  :group 'hnf)
(defface hnf-image-face
  '((((class color) (background light)) (:foreground "Blue"))
    (((class color) (background dark)) (:foreground "LightSkyBlue"))
    (t ()))
  "Face for image in hnf."
  :group 'hnf)
(defface hnf-comment-face
  '((((class color) (background light)) (:foreground "Red"))
    (((class color) (background dark)) (:foreground "Pink"))
    (t ()))
  "Face for image line in hnf."
  :group 'hnf)
(defface hnf-command-face
  '((((class color) (background light)) (:foreground "firebrick"))
    (((class color) (background dark)) (:foreground "Chocolate1"))
    (t ()))
  "Face for command in hnf."
  :group 'hnf)
(defface hnf-tilde-face
  '((((class color) (background light)) (:foreground "orange"))
    (((class color) (background dark)) (:foreground "orange"))
    (t ()))
  "Face for \"~\" in hnf."
  :group 'hnf)
(defface hnf-variable-face
  '((((class color) (background light)) (:foreground "DarkGoldenrod"))
    (((class color) (background dark)) (:foreground "LightGoldenrod"))
    (t ()))
  "Face for variable in hnf."
  :group 'hnf)

(defvar hnf-mode-map nil)
(defvar hnf-mode-command-map nil)

(defvar hnf-cat-face 'hnf-cat-face)
(defvar hnf-new-face 'hnf-new-face)
(defvar hnf-sub-face 'hnf-sub-face)
(defvar hnf-link-face 'hnf-link-face)
(defvar hnf-image-face 'hnf-image-face)
(defvar hnf-comment-face 'hnf-comment-face)
(defvar hnf-command-face 'hnf-command-face)
(defvar hnf-tilde-face 'hnf-tilde-face)
(defvar hnf-variable-face 'hnf-variable-face)

(defvar hnf-complete-ok t
  "If this is non-nil, \"OK\" is included for completion.")

(defconst hnf-completion-buffer-name "*HNF Completions*")

(defvar hnf-command-type-alist
  '((new . ((outline-level . 1)
	    (face . hnf-new-face)))
    (sub . ((outline-level . 2)
	    (face . hnf-sub-face)))))
(defmacro hnf-command-type-get-variable (type key)
  (` (cdr (assq (, key) (cdr (assq (, type) hnf-command-type-alist))))))

(defvar hnf-commands-table
  '(("NEW"	. ((type . new)
		   (args . (("title")))
		   (key . "n")))
    ("SUB"	. ((type . sub)
		   (args . (("title")))
		   (key . "s")))
    ("CAT"	. ((args . (("category" . ((complete . hnf-cat)))
			    any))
		   (face . hnf-cat-face)
		   (outline-level . 1)
		   (next-command . "NEW")
		   (key . "c")))

    ("LNEW"	. ((type . new)
		   (args . (link
			    ("title")))))
    ("RLNEW"	. ((type . new)
		   (args . (rlink
			    ("append")
			    ("title"))))) ; hns-2.10
    ("LSUB"	. ((type . sub)
		   (args . (link
			    ("title")))))
    ("RLSUB"	. ((type . sub)
		   (args . (rlink
			    ("append")
			    ("title"))))) ; hns-2.10

    ("P"	. ((need-close)
		   (key . "p"))) ; hns-2.10
    ("GRP"	. ((args . (("group" . ((complete . hnf-group)))
			    any))
		   (outline-level . 1))) ; hns-2.10

    ("LINK"	. ((args . (link
			    ("sentence")))
		   (key . "l")))
    ("URL"	. ((args . (("url" . ((face . hnf-link-face)))
			    ("sentence")))))
    ("RLINK"	. ((args . (rlink
			    ("append")
			    ("sentence")))))

    ("FONT"	. ((args . (("arg1")
			    ("arg2")
			    ("sentence")))))
    ("STRIKE"	. ((args . (("sentence")))))
    ("LSTRIKE"	. ((args . (link
			    ("sentence")))))
    ("STRONG"	. ((args . (("sentence")))))
    ("SPAN"	. ((args . (("class" . ((complete . hnf-class)))
			    ("sentence"))))) ; hns-2.10

    ("DIV"	. ((args . (("class" . ((complete . hnf-class)))))
		   (need-close))) ; hns-2.10
    ("IMG"	. ((args . (("place" . ((complete . (("r") ("l") ("n")))))
			    image
			    ("alt")))))
    ("LIMG"	. ((args . (link
			    ("place" . ((complete . (("r") ("l") ("n")))))
			    image
			    ("alt"))))) ; hns-2.10
    ("MARK"	. ((args . (("mark" . ((complete . hnf-mark)))))))

    ("UL"	. ((need-close)
		   (next-command . "LI")
		   (key . "u")))
    ("OL"	. ((need-close)
		   (next-command . "LI")
		   (key . "o")))
    ("LI"	. ((args . (("sentence")))))
    ("DL"	. ((need-close)
		   (next-command . "DT")
		   (key . "d"))) ; hns-2.10
    ("DT"	. ((args . (("sentence"))))) ; hns-2.10
    ("DD"	. ((args . (("sentence"))))) ; hns-2.10

    ("PRE"	. ((need-close))) ; hns-2.10
    ("CITE"	. ((need-close))) ; hns-2.10
    ("RT"	. ((need-close))) ; hns-2.2

    ("!"	. ((args . (("sentence")))
		   (face . hnf-comment-face)))
    ("!#"	. ((args . (("sentence")))
		   (face . hnf-comment-face)))
    ("FN"	. ((need-close)))
    ("ALIAS"	. ((args . (("alias" . ((complete . hnf-alias)))))))
    )
  "Table of hnf commands.")

(defmacro hnf-command-get-command (command-name)
  (` (assoc (, command-name) hnf-commands-table)))

(defmacro hnf-command-get-type (command)
  (` (cdr (assq 'type (cdr (, command))))))

(defmacro hnf-command-get-variable (command key)
  (` (cond ((cdr (assq (, key) (cdr (, command)))))
	   ((hnf-command-type-get-variable (hnf-command-get-type (, command))
					   (, key))))))
								 
(defmacro hnf-command-get-arg-detail (command count)
  (` (let ((args (hnf-command-get-variable (, command) 'args)))
       (if (or (eq (nth (, count) args) 'any)
	       (eq (nth 1 args) 'any))
	   (nth 0 args)
	 (nth (, count) args)))))

(defmacro hnf-command-need-close-p (command)
  (` (assq 'need-close (cdr (, command)))))

(defvar hnf-font-lock-keywords nil
  "Expressions to highlight in hnf mode.")

(defun hnf-font-lock-keywords-creation ()
  "Create font-lock-keywords from `hnf-commands-table'."
  (setq hnf-font-lock-keywords 
	(let ((commands hnf-commands-table)
	      command type face ret1 ret2 ret3)
	  (while (setq command (car commands))
	    (if (setq face (hnf-command-get-variable command 'face))
		(add-to-list 'ret1 (cons (concat "^" (car command) ".*") face))
	      (let ((args (hnf-command-get-variable command 'args))
		    (cnt 0)
		    arg)
		(while (setq arg (car args))
		  (if (setq face (cond ((eq arg 'link) 'hnf-link-face)
				       ((eq arg 'image) 'hnf-image-face)
				       ((consp arg)
					(cdr (assq 'face (cdr arg))))))
		      (add-to-list
		       'ret2
		       (list (concat "^" (car command) " +"
				     (apply (function concat)
					    (make-list cnt "[^ ]+ +"))
				     "\\([^ ]+\\)")
			     1 face)))
		  (setq cnt (1+ cnt)
			args (cdr args)))))
	    (add-to-list 'ret3
			 (if (hnf-command-need-close-p command)
			     (concat (car command) "\\|/" (car command))
			   (car command)))
	    (setq commands (cdr commands)))
	  (append ret1
		  ret2
		  (list
		   (cons (concat "^\\("
				 (mapconcat (function identity) ret3 "\\|")
				 "\\)\\>")
			 hnf-command-face))
		  (list
		   '(eval . (list
			     (concat "^\\("
				     (mapconcat (function car) hnf-variable "\\|")
				     "\\)\\>")
			     '(0 (if (hnf-header-p) hnf-variable-face)))))
		  (list (cons "~$" hnf-tilde-face))))))

(defvar hnf-outline-regexp
  (let ((commands hnf-commands-table)
	command outline-commands)
    (while (setq command (car commands))
      (if (hnf-command-get-variable command 'outline-level)
	  (add-to-list 'outline-commands (car command)))
      (setq commands (cdr commands)))
    (mapconcat (function identity) outline-commands "\\|"))
  "Regular expression to match the beginning of heading.")

(defvar hnf-imenu-generic-expression
  (let ((commands hnf-commands-table)
	command ret)
    (while (setq command (car commands))
      (if (eq (hnf-command-get-type command) 'new)
	  (let ((args (hnf-command-get-variable command 'args))
		(cnt -1))
	    (while args
	      (setq args (cdr args)
		    cnt (1+ cnt)))
	    (add-to-list 'ret
			 (list
			  nil
			  (concat "^" (car command) " "
				  (apply (function concat)
					 (make-list cnt "[^ ]+ "))
				  "\\(.*\\)")
			  1))))
      (setq commands (cdr commands)))
    ret)
  "Imenu generic expression for `hnf-mode'.  See `imenu-generic-expression'.")

(defun hnf-mode-set-keymap ()
  (setq hnf-mode-command-map (make-sparse-keymap))
  (let ((commands hnf-commands-table)
	command key)
    (while (setq command (car commands))
      (when (setq key (hnf-command-get-variable command 'key))
	(define-key hnf-mode-command-map key
	  `(lambda () (interactive) (hnf-insert-command ,(car command)))))
      (setq commands (cdr commands))))
  (setq hnf-mode-map (make-sparse-keymap))
  (define-key hnf-mode-map "\t" 'hnf-tab-complete)
  (define-key hnf-mode-map "\C-c\C-m" 'hnf-newline)
  (define-key hnf-mode-map "\C-c?" 'hnf-command-help)
  (define-key hnf-mode-map "\C-c=" 'hnf-get-link)
  (define-key hnf-mode-map "\C-c\C-f" 'hnf-link-find-file)
  (define-key hnf-mode-map "\C-c\C-t" 'hnf-insert-time)
  (define-key hnf-mode-map "\C-c\C-s" 'hnf-write-file-insert-time)
  (define-key hnf-mode-map "\C-c\C-b" 'hnf-browse-recent-diary)
  (define-key hnf-mode-map "\C-c\C-p" 'hnf-preview-diary)
  (define-key hnf-mode-map "\C-c\C-n" 'hnf-namazu)
  (define-key hnf-mode-map "\C-c\C-c" hnf-mode-command-map)
  )
(unless hnf-mode-map
  (hnf-mode-set-keymap))

;;;###autoload
(defun hnf-mode ()
  "Major mode for editing hnf.
\\{hnf-mode-map}"
  (interactive)
  (use-local-map hnf-mode-map)
  (setq mode-name "HNF")
  (setq major-mode 'hnf-mode)
  ;; font-lock
  (when hnf-font-lock-flag
    (require 'font-lock)
    (unless hnf-font-lock-keywords (hnf-font-lock-keywords-creation))
    (make-local-variable 'font-lock-defaults)
    (setq font-lock-defaults '(hnf-font-lock-keywords t))
    (font-lock-mode t))
  ;; outline
  (when hnf-outline-flag
    (make-local-variable 'outline-regexp)
    (setq outline-regexp hnf-outline-regexp)
    (make-local-variable 'outline-level)
    (setq outline-level (function hnf-outline-level))
    (outline-minor-mode 1))
  ;; imenu
  (make-local-variable 'imenu-generic-expression)
  (setq imenu-generic-expression hnf-imenu-generic-expression)
  ;; hook
  (and (functionp hnf-initial-function)
       (= (buffer-size) 0)
       (buffer-file-name)
       (not (file-exists-p (buffer-file-name)))
       (funcall hnf-initial-function))
  (run-hooks 'hnf-mode-hook))

;;;###autoload
(defun hnf (&optional arg)
  "Open hnf of today.
If numerical argument is specified, open hnf of that days ago."
  (interactive "P")
  (let* ((days-ago (if (listp arg) nil arg))
	 (now (hnf-current-time days-ago))
	 (dir (concat hnf-diary-dir "/"
		      (and hnf-diary-year-directory-flag
			   (hnf-format-time-string "%Y/" now))))
	 (name (concat dir (unless (and arg (listp arg))
			     (hnf-format-time-string "d%Y%m%d.hnf" now)))))
    (if (and arg (listp arg)) (setq name (read-file-name "Find file: " name)))
    (or (file-directory-p (file-name-directory name))
	(make-directory  dir))
    (find-file name)
    (hnf-mode)))

(defun hnf-tab-complete ()
  "Complete and expantion in hnf."
  (interactive)
  (let ((spaces (hnf-count-spaces))
	(command-word (hnf-command-word))
	detail complete-list)
    (cond ((hnf-header-p) ; header part
	   (or (and (eq spaces 0)
		    (or (and hnf-variable
			     (not (eq (hnf-complete hnf-variable) 'no-match)))
			(and hnf-complete-ok
			     (not (eq (hnf-complete '(("OK"))) 'no-match)))))
	       (funcall hnf-tab-command)))
	  ((eq (setq detail (and (> spaces 0)
				 (hnf-command-get-arg-detail
				  (hnf-command-get-command command-word)
				  (1- spaces))))
	       'rlink)
	   (hnf-complete hnf-rlink))
	  ((or (eq detail 'link) (eq detail 'image))
	   (hnf-complete-link))
	  ((setq complete-list (cdr (assq 'complete (cdr detail))))
	   (hnf-complete
	    (if (symbolp complete-list)
		(symbol-value complete-list)
	      complete-list)))
	  ((and (string= "/" command-word) (= spaces 0))
	   (hnf-close-command))
	  ((and (= spaces 0)
		(not (eq (hnf-complete-command) 'no-match))))
	  (t
	   (funcall hnf-tab-command)))))

(defun hnf-insert-command (command-name)
  (let* ((command (hnf-command-get-command command-name))
	 (args (hnf-command-get-variable command 'args))
	 (detail (car args))
	 prompt complete-list m p)
    (insert command-name)
    (setq p (point))
    (when (hnf-command-need-close-p command)
      (save-excursion
	(insert "\n" "/" command-name "\n")))
    (when (hnf-command-get-variable command 'next-command)
      (hnf-insert-command (hnf-command-get-variable command 'next-command)))
    (set-marker (setq m (make-marker)) (point))
    (set-marker-insertion-type m t)
    (goto-char p)
    (if detail
	(progn
	  (insert " ")
	  (save-excursion (insert "\n"))
	  (cond ((eq detail 'rlink)
		 (setq prompt "rlink"
		       complete-list hnf-rlink))
		((setq complete-list (cdr (assq 'complete (cdr-safe detail))))
		 (when (symbolp complete-list)
		   (setq complete-list (symbol-value complete-list)))
		 (setq prompt (car detail))))
	  (if complete-list
	      (progn
		(insert (completing-read (concat prompt ": ") complete-list))
		(unless (or (= (length args) 1)
			(eq (nth 1 args) 'any))
		  ;; rest args
		  (insert " ")
		  (set-marker m (point))))
	    ;; some args.
	    (set-marker m (point))))
      (insert "\n"))
    (goto-char (marker-position m))
    (set-marker m nil)))

;;; various command
(defun hnf-newline ()
  "Insert newline and various string fit for the situation."
  (interactive)
  (let* ((command-word (hnf-command-word))
	 (command (hnf-command-get-command command-word))
	 (case-fold-search nil)
	 str)
    (when (hnf-command-need-close-p command)
      (save-excursion (insert (concat "\n/" command-word "\n"))))
    (newline)
    (when (hnf-command-get-variable command 'next-command)
      (hnf-insert-command (hnf-command-get-variable command 'next-command)))))

(defun hnf-command-help (&optional command-word)
  "Display help of command."
  (interactive "P")
  (unless command-word (setq command-word (hnf-command-word)))
  (let ((command (hnf-command-get-command command-word))
	mes)
    (when command
      (setq mes command-word)
      (let ((args (hnf-command-get-variable command 'args))
	    arg)
	(while (setq arg (car args))
	  (setq mes (concat mes " " (if (symbolp arg)
					(if (eq arg 'any)
					    "[...]"
					  (symbol-name arg))
				      (car arg)))
		args (cdr args)))
	(message mes)))))

(defun hnf-link-find-file ()
  "Open file specifed by LINK or LSUB.
Suppore only relative path."
  (interactive)
  (if (eq (hnf-command-get-arg-detail
	   (hnf-command-get-command (hnf-command-word))
	   0)
	  'link)
      (let (p fname)
	(save-excursion
	  (beginning-of-line)
	  (skip-chars-forward "^ \t\n")
	  (skip-chars-forward " ")
	  (setq p (point))
	  (skip-chars-forward "^ \t\n#")
	  (setq fname (buffer-substring-no-properties p (point))))
	(if (string-match "^\\(http\\|ftp\\)://" fname)
	    (funcall hnf-browse-url-browser-function fname)
	  (setq fname (expand-file-name fname
					(if (char-equal (string-to-char fname)
							?/)
					    hnf-document-root
					  hnf-html-dir)))
	  (when (file-directory-p fname)
	    (when (not (string-match "/$" fname))
	      (setq fname (concat fname "/")))
	    (let ((index-list hnf-index-name-list))
	      (while (and index-list
			  (not (file-exists-p
				(concat fname (car index-list)))))
		(setq index-list (cdr index-list)))
	      (if index-list
		  (setq fname (concat fname (car index-list)))
		(setq fname
		      (read-file-name "Find file: " fname)))))
	  (find-file fname)))))

(defun hnf-get-link (&optional arg)
  "Obtain name of NEW or SUB."
  (interactive "P")
  (let ((date-list (hnf-buffer-hnf-p)))
    (if (null date-list)
	(error "This is not hnf")
      (let ((day-num (string-to-number (nth 2 date-list)))
	    (command-word (hnf-command-word))
	    command-type
	    new-cnt sub-cnt link-name)
	(save-excursion
	  (when (eq (setq command-type
			  (hnf-command-get-type
			   (hnf-command-get-command command-word)))
		    'sub)
	    (setq sub-cnt 1)
	    (while (and (= (forward-line -1) 0)
			(not (eq
			      (setq command-type
				    (hnf-command-get-type
				     (hnf-command-get-command
				      (setq command-word (hnf-command-word)))))
			      'new)))
	      (if (eq command-type 'sub)
		  (setq sub-cnt (1+ sub-cnt)))))
	  (when (eq command-type 'new)
	    (setq new-cnt 1)
	    (while (= (forward-line -1) 0)
	      (if (eq (hnf-command-get-type
		       (hnf-command-get-command (hnf-command-word)))
		      'new)
		  (setq new-cnt (1+ new-cnt))))))
	(when new-cnt
	  (let* ((fmt (if sub-cnt hnf-sub-link-name-format
			hnf-new-link-name-format))
		 (fmt-spec (list
			    (cons ?Y (nth 0 date-list))
			    (cons ?m (nth 1 date-list))
			    (cons ?d (nth 2 date-list))
			    (cons ?h (number-to-string (/ day-num 10)))
			    (cons ?a (cond ((< day-num 11) "a")
					   ((< day-num 21) "b")
					   (t "c")))
			    (cons ?N (number-to-string new-cnt))
			    (cons ?S (if sub-cnt (number-to-string sub-cnt)))))
		 (fmt-len (length fmt))
		 (ind 0)
		 (result "")
		 cur-char)
	    (while (< ind fmt-len)
	      (setq cur-char (aref fmt ind))
	      (setq result
		    (concat result
			    (if (eq cur-char ?%)
				(progn
				  (setq ind (1+ ind)
					cur-char (aref fmt ind))
				  (or (cdr (assq cur-char fmt-spec))
				      (char-to-string cur-char)))
			      (char-to-string cur-char))))
	      (setq ind (1+ ind)))
	    (message "%s" result)
	    (if arg (kill-new result))))))))

(defun hnf-insert-time (&optional arg)
  "Insert time stamp."
  (interactive "P")
  (if (and arg
	   (re-search-forward hnf-time-regexp nil t))
      (replace-match
       (save-match-data
	 (hnf-format-time-string hnf-time-format (hnf-current-time))))
    (insert (hnf-format-time-string hnf-time-format (hnf-current-time)))))

(defun hnf-write-file-insert-time ()
  "Execute `hnf-insert-time', and save file."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (hnf-insert-time))
  (save-buffer))

(defun hnf-check ()
  "Check curernt hnf file."
  (interactive)
  (let ((case-fold-search nil)
	word)
    ;; find all capitalized word in top of line
    (save-excursion
      (goto-char (point-min))
      (search-forward "\n\n" nil t)
      (while (re-search-forward "^/?\\([A-Z]+\\)\\([ \t]\\|$\\)" nil t)
	;; is it valid command?
	(unless (assoc (setq word (match-string 1)) hnf-commands-table)
	  (if (y-or-n-p (format "Undefined keyword '%s'.  Insert space? "
				word))
	      (save-excursion
		(goto-char (match-beginning 0))
		(insert " "))
	    ;; leave it
	    (error "Edit it!")))))
    (if (interactive-p)
	(message "Good!"))))

;;; for namazu.el
(defun hnf-namazu (key)
  (interactive
   (progn
     (require 'namazu)
     (list (read-from-minibuffer "Enter Keyword: " nil
				 (if (boundp 'namazu-minibuffer-field-map)
				     namazu-minibuffer-field-map)
				 nil 'namazu-history))))
  (namazu 0 hnf-namazu-index-dir key))

(defun hnf-namazu-find-file ()
  "Open hnf at point in \*namazu\*."
  (interactive)
  (save-excursion
    (if (re-search-forward
	 "#\\([1-9][0-9][0-9][0-9]\\)\\([0-1][0-9][0-3][0-9]\\)0" nil t)
	(find-file (concat hnf-diary-dir "/"
			   (and hnf-diary-year-directory-flag
				(concat (match-string 1) "/"))
			   "d" (match-string 1) (match-string 2) ".hnf")))))

;;; for calendar.el
(eval-when-compile (require 'calendar))

(defun hnf-filename-from-date (date)
  (concat hnf-diary-dir "/"
	  (and hnf-diary-year-directory-flag
	       (format "%d/" (extract-calendar-year date)))
	  (format "d%04d%02d%02d.hnf"
		  (extract-calendar-year date)
		  (extract-calendar-month date)
		  (extract-calendar-day date))))

;;;###autoload
(defun hnf-insert-diary-entry ()
  "Open hnf for the date indicated by point."
  (interactive)
  (find-file-other-window
   (hnf-filename-from-date (calendar-cursor-to-date t))))

;;;###autoload
(defun hnf-mark-diary-entries ()
  "Mark days in the calendar window that have hnf."
  (interactive)
  (let (y m first-date last-date tmp)
    (save-excursion
      (set-buffer calendar-buffer)
      (setq m displayed-month)
      (setq y displayed-year))
    (increment-calendar-month m y -1)
    (setq first-date
          (calendar-absolute-from-gregorian (list m 1 y)))
    (increment-calendar-month m y 2)
    (setq last-date
          (calendar-absolute-from-gregorian
           (list m (calendar-last-day-of-month m y) y)))
    (calendar-for-loop date from first-date to last-date do
		       (if (file-exists-p
			    (hnf-filename-from-date
			     (setq tmp
				   (calendar-gregorian-from-absolute date))))
			   (mark-visible-calendar-date tmp)))))

;;; for browse-url
(defun hnf-browse-recent-diary ()
  "Ask a WWW browser to load recent diary."
  (interactive)
  (let ((browse-url-browser-function hnf-browse-url-browser-function))
    (browse-url hnf-diary-url)))

(defun hnf-browse-diary ()
  "Ask a WWW browser to load current editting diary."
  (interactive)
  (let ((date-list (hnf-buffer-hnf-p))
	(browse-url-browser-function hnf-browse-url-browser-function))
    (if (null date-list)
	(error "This is not hnf")
      (browse-url (concat hnf-diary-url "?"
			  (mapconcat (function identity) date-list ""))))))

(defvar hnf-temp-file-list '())

(defun hnf-preview-diary ()
  "Ask a WWW browser to load current editting diary."
  (interactive)
  (let ((date-list (hnf-buffer-hnf-p))
	(browse-url-browser-function hnf-browse-url-browser-function))
    (if (null date-list)
        (error "This is not hnf")
      (let ((temp-file (concat temporary-file-directory
			       "hnf" (apply (function concat) date-list)
			       ".html"))
            (default-directory (file-name-directory hnf-hns-program)))
        (with-temp-file temp-file
          (call-process hnf-hns-program nil t t
			(apply (function concat) date-list)))
        (browse-url-of-file temp-file)
	(add-to-list 'hnf-temp-file-list temp-file)))))

(defun hnf-delete-temp-file-list ()
  "Remove file of `hnf-temp-file-list'."
  (while hnf-temp-file-list
    (if (file-exists-p (car hnf-temp-file-list))
	(delete-file (car hnf-temp-file-list)))
    (setq hnf-temp-file-list (cdr hnf-temp-file-list))))
(add-hook 'kill-emacs-hook 'hnf-delete-temp-file-list)

;;; miscellaneous functions
(defun hnf-buffer-hnf-p (&optional buffer)
  "Judge whether buffer is hnf.
If buffer is ommitted, judge for `current-buffer'.
If buffer is hnf, return list of (year mon day)."
  (let ((fname (buffer-file-name buffer)))
    (if (and fname
	     (string-match
	      "d\\([0-9][0-9][0-9][0-9]\\)\\([0-1][0-9]\\)\\([0-3][0-9]\\)\\.hnf"
	      (setq fname (file-name-nondirectory fname))))
	(list (match-string 1 fname)
	      (match-string 2 fname)
	      (match-string 3 fname)))))

(defun hnf-header-p ()
  "Judge whether in header."
  (save-excursion
    (not (search-backward "\n\n" nil t))))

(defun hnf-count-spaces ()
  "Count space character from beginning of line to point."
  (save-excursion
    (let ((p (point))
	  (cnt 0))
      (beginning-of-line)
      (while (re-search-forward "[ \t]+" p t)
	(setq cnt (+ cnt 1)))
      cnt)))

(defun hnf-cur-word (&optional erase)
  "Extract word at point."
  (save-excursion
    (let ((p (point))
	  string)
      (skip-chars-backward "^ \t\n")
      (setq string (buffer-substring-no-properties p (point)))
      (if erase (delete-region p (point)))
      string)))

(defun hnf-command-word ()
  "Obtain command word at the line."
  (save-excursion
    (beginning-of-line)
    (let ((p (point)))
      (skip-chars-forward "^ \t\n")
      (buffer-substring-no-properties p (point)))))

(defun hnf-close-command ()
  "Insert close command."
  (let ((commands hnf-commands-table)
	command close-commands regexp stack command)
    (while (setq command (car commands))
      (if (hnf-command-need-close-p command)
	  (add-to-list 'close-commands (car command)))
      (setq commands (cdr commands)))
    (setq regexp
	  (concat "^/?\\("
		  (mapconcat (function identity) close-commands "\\|")
		  "\\)$"))
    (save-excursion
      (while (progn
	       (or (re-search-backward regexp nil t)
		   (error "Command unmatch"))
	       (setq command (match-string 1))
	       (if (eq (char-after) ?/)
		   (push command stack)
		 (if (string= command (car stack))
		     (pop stack))))))
    (if stack (error "%s unmatched" command))
    (if command (insert command))))

(defun hnf-current-time (&optional days-ago)
  "Return `current-time'.
But, if `hnf-hour-not-today' is set, return the time of specified hours ago."
  (let ((time (current-time)))
    (if (not (numberp days-ago)) (setq days-ago 0))
    (hnf-time-float (- (hnf-float-time time)
		       (* days-ago 24 60 60)
		       (* (or hnf-hour-not-today 0) 60 60)))))

(defun hnf-format-time-string (time-format &optional time)
  "Same as `format-time-string'.
But, \"%H\" is translated into feature hour for `hnf-hour-not-today'."
  (let ((case-fold-search nil)
	sub-format hour)
    (while (string-match "%[a-zA-Z]" time-format)
      (setq sub-format (match-string 0 time-format))
      (setq time-format
	    (replace-match
	     (if (string= sub-format "%H")
		 (format "%d"
			 (+ (or hnf-hour-not-today 0)
			    (string-to-number (format-time-string "%H" time))))
	       (format-time-string sub-format time))
	     nil nil time-format)))
    time-format))

(defalias 'hnf-float-time
  (if (fboundp 'float-time) ; emacs21
      'float-time
    (lambda (&optional tm)
      (let ((time (or tm (current-time))))
	(+ (* (float (ash 1 16)) (nth 0 time)) (float (nth 1 time)))))))
  
(defun hnf-time-float (num)
  (let* ((most-time (floor num 65536))
	 (least-time (floor (- num (* 65536.0 most-time)))))
    (list most-time least-time 0)))

(defun hnf-outline-level ()
  "Return the depth to which a statement is nested in the outline.
Point must be at the beginning of a header line.
See `hnf-commands-table'."
  (save-excursion
    (if (looking-at outline-regexp)
	(hnf-command-get-variable
	 (hnf-command-get-command
	  (buffer-substring (match-beginning 0) (match-end 0)))
	 'outline-level))))

(eval-after-load "speedbar"
  '(speedbar-add-supported-extension ".hnf"))

;;; upper function for completion
(defun hnf-complete (alist)
  "Complete at point.  ALIST is set of permissible completions."
  (hnf-complete-string (hnf-cur-word t) alist))

(defun hnf-complete-link ()
  "Complete LINK."
  (let* ((cur (hnf-cur-word t))
	 (dname (file-name-directory cur))
	 (fname (file-name-nondirectory cur))
	 (basedir (cond ((char-equal (string-to-char cur) ?/)
			 (concat hnf-document-root dname))
			(dname
			 (expand-file-name dname hnf-html-dir))
			(t
			 hnf-html-dir)))
	 files)
    (when (file-directory-p basedir)
      (setq files (file-name-all-completions fname basedir)))
    (if (null files) 
	(when (require 'w3m nil t)
	  (w3m-arrived-setup)
	  (mapatoms (lambda (x)
		      (when x (push (list (symbol-name x)) files)))
		    w3m-arrived-db)
	  (hnf-complete-string cur files))
      (when dname (insert dname))
      (hnf-complete-string fname (mapcar (function list) files)))))

(defun hnf-complete-command ()
  "Complete command name."
  (let ((sts (hnf-complete hnf-commands-table)))
    (when (eq sts 'match)
      (if (null (hnf-command-get-variable
		 (hnf-command-get-command (hnf-command-word)) 'args))
	  (if hnf-complete-command-insert-newline-function
	      (funcall hnf-complete-command-insert-newline-function))
	(and hnf-complete-command-insert-space-flag (insert " "))))
    sts))

;;; lower function for completion
(defun hnf-complete-string (string alist)
  (let* ((completion-ignore-case t)
	 (completions (all-completions string alist))
	 (cur (current-buffer))
	 comp)
    (cond
     ((= (length completions) 1) ; only one.
      (if (string= (car completions) string)
	  (progn
	    (insert (car completions))
	    (hnf-delete-completion-window))
	(insert (car completions)))
      'match)
     ((and (setq comp (try-completion string alist))
	   (not (string= comp string))) ; halfway
      (insert comp)
      'complete)
     (t
      (insert string)
      (if (not comp)
	  (progn ; no match
	    (hnf-delete-completion-window)
	    'no-match)
	; display
	(buffer-disable-undo (get-buffer-create hnf-completion-buffer-name))
	(with-output-to-temp-buffer
	    hnf-completion-buffer-name
	  (display-completion-list (sort completions 'string<)))
	'complete-list)))))
  
(defun hnf-delete-completion-window ()
  (and
   (get-buffer hnf-completion-buffer-name)
   (let ((w (get-buffer-window hnf-completion-buffer-name)))
     (and w
	  (delete-window w))
     (kill-buffer hnf-completion-buffer-name))))

(run-hooks 'hnf-mode-load-hook)

(provide 'hnf-mode)
;;; hnf-mode.el ends here

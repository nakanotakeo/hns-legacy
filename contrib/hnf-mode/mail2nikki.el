;;; mail2nikki.el --- functions for mail2nikki

;; Copyright (C) 1999-2000 by Akihiro Arisawa <ari@nijino.com>

;; Author: Akihiro Arisawa <ari@nijino.com>
;; Version: $Id: mail2nikki.el,v 3.4 2001/09/15 14:38:00 ari Exp $
;; Keywords: mail nikki hnf hns

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

;;; Commentary:

;; 【使い方】
;; M-x mew-nikki-send
;; M-x message-nikki-send
;; M-x wl-nikki-send
;;
;; 【設定例】
;; (autoload 'mew-nikki-send "mail2nikki" nil t)
;; (autoload 'message-nikki-send "mail2nikki" nil t)
;; (autoload 'wl-nikki-send "mail2nikki" nil t)
;; (setq mail2nikki-to-address "hoge@foo.bar.jp")
;; (setq mail2nikki-password "hirakegoma")

;;; Code:
(defvar mail2nikki-to-address nil
  "送信先のメールアドレスです。")

(defvar mail2nikki-cc-address nil
  "送信時のCcに指定するメールアドレスです。")

(defvar mail2nikki-password nil
  "mail2nikkiのパスワードです。")

(defvar mail2nikki-subject-list '("hnf:ADD" "hnf:DEL" "hnf:DEL&ADD" "hnf:GET")
  "mail2nikkiのSubjectのリストです。最初の要素がデフォルトとなります。"
  )

(defvar mail2nikki-insert-end t
  "non-nilを指定すると*-nikki-sendを実行時にENDを挿入します。")

(defvar mail2nikki-hook nil
  "*-nikki-sendのhook")

(require 'hnf-mode)
(if hnf-font-lock-flag (require 'font-lock))

(defvar mew-nikki-mode-map nil)
(defvar message-nikki-mode-map nil)
(defvar wl-nikki-mode-map nil)

;;;###autoload
(defun mew-nikki-send (&optional arg)
  (interactive "P")
  (or (featurep 'mail2nikki-mew) (mail2nikki-mew-setup))
  (mail2nikki-nikki-send 'mail2nikki-mew-func mew-nikki-mode-map
			 'mew-nikki-font-lock-keywords nil arg))

;;;###autoload
(defun message-nikki-send (&optional arg)
  (interactive "P")
  (or (featurep 'mail2nikki-message) (mail2nikki-message-setup))
  (mail2nikki-nikki-send 'mail2nikki-message-func message-nikki-mode-map
			 'message-nikki-font-lock-keywords nil arg))

;;;###autoload
(defun wl-nikki-send (&optional arg)
  (interactive "P")
  (or (featurep 'mail2nikki-wl) (mail2nikki-wl-setup))
  (mail2nikki-nikki-send 'mail2nikki-wl-func wl-nikki-mode-map
			 nil 'mail2nikki-wl-complete-field-body-or-tab arg))

(defun mail2nikki-nikki-send (mail-func map keywords tab-command arg)
  ; ドラフトの用意
  (let ((subject (if arg
		     (completing-read "Subject: "
				      (mapcar 'list mail2nikki-subject-list)
				      nil t "hnf:")
		   (car mail2nikki-subject-list))))
    (funcall mail-func mail2nikki-to-address mail2nikki-cc-address subject))
  ; いろいろ挿入
  (insert (format "PASSWORD: %s\n" mail2nikki-password))
  (insert (format "DATE: %s\n\n" (format-time-string "%Y%m%d" (current-time))))
  (if mail2nikki-insert-end (save-excursion (insert "\nEND\n")))
  ; キーマップの変更
  (make-local-variable 'hnf-tab-command)
  (setq hnf-tab-command (if tab-command tab-command (key-binding "\t")))
  (use-local-map map)
  ; font-lock関係
  (if (and hnf-font-lock-flag keywords)
      (progn
	(make-local-variable 'font-lock-defaults)
	(setq font-lock-defaults `(,keywords t))
	(turn-on-font-lock)))
  ; 補完の調整
  (make-local-variable 'hnf-commands-table)
  (setq hnf-commands-table (append hnf-commands-table '(("END"))))
  (make-local-variable 'hnf-complete-ok)
  (setq hnf-complete-ok nil)
  ; 雑多なこと
  (set-buffer-modified-p nil)
  (run-hooks 'mail2nikki-hook))

(defun mail2nikki-mew-setup ()
  (require 'mew)

  (defvar mew-nikki-font-lock-keywords hnf-font-lock-keywords)

  (if mew-nikki-mode-map
      ()
    (setq mew-nikki-mode-map (copy-keymap mew-draft-mode-map))
    (define-key mew-nikki-mode-map "\t" 'hnf-tab-complete))
  
  (defun mail2nikki-mew-func (to cc subject)
    (mew-send to cc subject)
    (goto-char (mew-header-end))
    (forward-line 1))

  (provide 'mail2nikki-mew))

(defun mail2nikki-message-setup ()
  (require 'message)

  (defvar message-nikki-font-lock-keywords
    (append message-font-lock-keywords hnf-font-lock-keywords))

  (if message-nikki-mode-map
      ()
    (setq message-nikki-mode-map (copy-keymap message-mode-map))
    (define-key message-nikki-mode-map "\t" 'hnf-tab-complete))

  (defun mail2nikki-message-func (to cc subject)
    (message-mail to subject (and cc `((Cc . ,cc))))
    (message-goto-body))

  (provide 'mail2nikki-message))

(defun mail2nikki-wl-setup ()
  (require 'wl)

  (defvar wl-nikki-font-lock-keywords hnf-font-lock-keywords)

  (if wl-nikki-mode-map
      ()
    (setq wl-nikki-mode-map (copy-keymap wl-draft-mode-map))
    (define-key wl-nikki-mode-map "\t" 'hnf-tab-complete))

  (defun mail2nikki-wl-complete-field-body-or-tab ()
    (wl-complete-field-body-or-tab))

  (defun mail2nikki-wl-func (to cc subject)
    (wl-draft to subject nil cc)
    (goto-char (point-max)))

  (provide 'mail2nikki-wl))

(provide 'mail2nikki)
;;; mail2nikki.el ends here

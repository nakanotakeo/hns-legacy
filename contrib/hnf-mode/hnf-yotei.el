;;; hnf-yotei.el --- major mode for HyperNikkiSystem yotei file

;; Copyright (C) 1999-2000 by Akihiro Arisawa <ari@nijino.com>

;; Author: Akihiro Arisawa <ari@nijino.com>
;; Version: $Id: hnf-yotei.el,v 3.4 2000/08/15 08:04:04 ari Exp $
;; Keywords: hns nikki yotei

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

;; 【特徴】
;; HNSのNヵ月分の予定の入力を一つのバッファで行えます。(Nはデフォルト3)
;;
;; 【設定】
;; 1. hnf-mode.el, hnf-yotei.el をload-pathの通ったところに置きます。
;; 2. ~/.emacs に以下の記述をします。
;;    (autoload 'yotei "hnf-yotei" nil t)
;;
;; 【使い方】
;; 1. M-x yotei で*yotei*バッファを開きます。
;; 2. 適宜編集します。
;; 3. C-xC-sで保存します。
;;
;; 【バグ or 仕様】
;; 1. hnf-yotei-diary-year-directorypをtにしている場合、存在しないディレクトリ
;;    に書き込みにいってエラーになる可能性があります。
;;
;; 【Emacsen】
;; 開発はemacs-20で行っています。
;; XEmacs-20/21やmule-2.3@emacs-19.34でも動くとは思います。
;;
;; 【謝辞】
;; all.elをかなり参考にさせていただきました。作者である、Per Abrahamsenさんに
;; 多大に感謝します。

;;; Code:
(require 'hnf-mode)

(defvar hnf-yotei-range 3)
(defvar hnf-yotei-diary-year-directory-flag hnf-diary-year-directory-flag)

(defvar hnf-yotei-buffer nil)
(defvar hnf-yotei-mode-map nil)
(defvar hnf-yotei-hook nil)

(if hnf-yotei-mode-map nil
  (setq hnf-yotei-mode-map (make-sparse-keymap))
  (define-key hnf-yotei-mode-map "\C-x\C-s" 'hnf-yotei-save))

(defun hnf-yotei (&optional arg)
  "HNSの予定を記述するモード"
  (interactive "P")
  (let* ((this-year (nth 5 (decode-time)))
	 (this-month (nth 4 (decode-time)))
	 (year this-year)
	 (month this-month)
	 (range (cond ((null arg)
		       hnf-yotei-range)
		      ((listp arg)
		       (string-to-number (read-from-minibuffer
					  "何ヶ月分編集しますか?: "
					  (number-to-string hnf-yotei-range))))
		      ((integerp arg)
		       arg)))
	 (r 0))
    (if (<= range 0) (setq range hnf-yotei-range))
    
    (switch-to-buffer (setq hnf-yotei-buffer (get-buffer-create "*yotei*")))

    (if (buffer-modified-p) nil
      ; 準備
      (let ((inhibit-read-only t))
	(erase-buffer)
	(mapcar (function delete-overlay)
		(overlays-in (point-min) (point-max))))
      ; ファイルの読込み
      (while (< r range)
	(hnf-yotei-open-and-insert year month)
	(setq month (1+ month))
	(if (= month 13)
	    (setq year (1+ year)
		  month 1))
	(setq r (1+ r)))
      ; 仕掛いろいろ
      (hnf-yotei-set-insert-behind-hooks)
      (setq buffer-undo-list nil)
      (set-buffer-modified-p nil))
    (use-local-map hnf-yotei-mode-map)
    (setq mode-name "YOTEI")
    (setq major-mode 'hnf-yotei)
    (run-hooks 'hnf-yotei-hook)
    ))

(defalias 'yotei 'hnf-yotei)

(defun hnf-yotei-open-and-insert (year month)
  (let ((file (concat hnf-diary-dir "/"
		      (and hnf-yotei-diary-year-directory-flag
			   (concat (number-to-string year) "/"))
		      (format "y%4d%02d" year month)))
	(beg (point))
	(marker (make-marker))
	overlay)
    ;; 年月の表示
    (insert (format "%4d年%02d月\n" year month))
    (put-text-property beg (point) 'rear-nonsticky t)
    (put-text-property beg (point) 'face 'highlight)
    (put-text-property beg (point) 'intangible t)
    (put-text-property beg (1- (point)) 'read-only t)
    ;; *yotei*に挿入
    (setq beg (point))
    (if (file-exists-p file) (insert-file-contents file) (insert "\n"))
    (goto-char (point-max))
    (overlay-put (setq overlay (make-overlay beg (point))) 'file file)
    ))

(defun hnf-yotei-set-insert-behind-hooks ()
  (let ((overlays (overlays-in (point-min) (point-max)))
	overlay)
    (while (setq overlay (car overlays))
      (overlay-put overlay 'insert-behind-hooks '(hnf-yotei-extent-overlay))
      (setq overlays (cdr overlays)))))

(defun hnf-yotei-extent-overlay (overlay &rest junk)
  "overlayをカーソル位置まで伸ばします。"
  (move-overlay overlay (overlay-start overlay) (point)))

(defun hnf-yotei-save ()
  (interactive)
  (let ((require-final-newline t)
	(overlays (overlays-in (point-min) (point-max)))
	overlay file content)
    (while (setq overlay (car overlays))
      (if (setq file (overlay-get overlay 'file))
	  (write-region (overlay-start overlay) (overlay-end overlay) file))
      (setq overlays (cdr overlays)))
    (set-buffer-modified-p nil)))

(provide 'hnf-yotei)
;;; hnf-yotei.el ends here

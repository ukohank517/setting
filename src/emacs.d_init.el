(package-initialize)

(setq package-archives
      '(("gnu" . "http://elpa.gnu.org/packages/")
        ("melpa" . "http://melpa.org/packages/")
        ("org" . "http://orgmode.org/elpa/")))

(setq default-input-method "MacOSX")


;;; windows move                                                                                                       
(global-set-key (kbd "ESC <left>")  'windmove-left)
(global-set-key (kbd "ESC <down>")  'windmove-down)
(global-set-key (kbd "ESC <up>")    'windmove-up)
(global-set-key (kbd "ESC <right>") 'windmove-right)

;; バックアップファイル(*~)を作成しない                                                                                
(setq make-backup-files nil)
;; ロックファイルを作らない(#*)を作成しない                                                                            
;; (setq auto-save-default nil)                                                                                        




;;;flymake                                                                                                             

;; Added by Package.el.  This must come before configurations of                                                       
;; installed packages.  Don't delete this line.  If you don't want it,                                                 
;; just comment it out by adding a semicolon to the start of the line.                                                 
;; You may delete these explanatory comments.                                                                          

(require 'flymake)

;;エラーメッセージをミニバッファで表示させる                                                                           
;;(global-set-key "\C-e" 'flymake-goto-next-error)                                                                     
;;(global-set-key "\M-e" 'flymake-goto-prev-error)                                                                     

;;ibusのcpu使用率上昇を抑えられるかも？                                                                                
(setq popwin:close-popup-window-timer-interval 0.05)

;; gotoした際にエラーメッセージをminibufferに表示する                                                                  
(defun display-error-message ()
  (message (get-char-property (point) 'help-echo)))
(defadvice flymake-goto-prev-error (after flymake-goto-prev-error-display-message)
  (display-error-message))
(defadvice flymake-goto-next-error (after flymake-goto-next-error-display-message)
  (display-error-message))
(ad-activate 'flymake-goto-prev-error 'flymake-goto-prev-error-display-message)
(ad-activate 'flymake-goto-next-error 'flymake-goto-next-error-display-message)

;;c++のflymakeでmakefileを不要にする                                                                                   
(defun flymake-cc-init ()
  (let* ((temp-file   (flymake-init-create-temp-buffer-copy
               'flymake-create-temp-inplace))
         (local-file  (file-relative-name
               temp-file
               (file-name-directory buffer-file-name))))
    (list "g++" (list "-Wall" "-Wextra" "-fsyntax-only" local-file))))

(push '("\\.cc$" flymake-cc-init) flymake-allowed-file-name-masks)
(push '("\\.cpp$" flymake-cc-init) flymake-allowed-file-name-masks)
(push '("\\.h$" flymake-cc-init) flymake-allowed-file-name-masks)
(push '("\\.hpp$" flymake-cc-init) flymake-allowed-file-name-masks)

(add-hook 'c++-mode-hook '(lambda ()
  (flymake-mode t)
))

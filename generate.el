(straight-use-package 'webfeeder)
(defvar oh/pandoc-template
  "pandoc --to html5+smart --template=template.html --css tufte.css --self-contained --resource-path posts -o docs/%s %s")

(defun oh/pandoc-to-html (file &optional output)
  (shell-command
   (format oh/pandoc-template
	   (if output
	       output
	     (concat (file-name-sans-extension file) ".html"))
	   file)))

(defun oh/generate-files ()
  (let* ((postdir "posts/")
	 (posts (directory-files postdir nil "\\.org$")))
    (mapcar (lambda (f)
	      (oh/pandoc-to-html (concat postdir f)))
	    posts)))

(defun oh/get-org-keyword (file key)
  (when (and file
	     (file-exists-p file))
    (save-window-excursion
      (find-file file)
      (cadar (org-collect-keywords `(,key))))))

(defun oh/generate-index ()
  (let* ((indx "index.org")
	 (mainpage "main.org")
	 (postdir "posts/")
	 (posts (directory-files (concat "docs/" postdir) nil "\\.html$")))
    (save-window-excursion
      (find-file indx)
      (erase-buffer)
      (insert-file-contents mainpage)
      (end-of-buffer)
      (mapcar (lambda (pfile)
		(let* ((name (file-name-sans-extension pfile))
		       (ffull (concat postdir pfile))
		       (orgtitle (oh/get-org-keyword
				  (concat postdir name ".org")
				  "TITLE"))
		       (brief (oh/get-org-keyword
			       (concat postdir name ".org")
			       "BRIEF"))
		       (briefstring (if brief
					brief
				      ""))
		       (tags (oh/get-org-keyword
			      (concat postdir name ".org")
			      "TAGS"))
		       (tagstring (if tags
				      tags
				    ""))
		       (title (if orgtitle
				  orgtitle
				(file-name-sans-extension pfile)))
		       (entry (format "| [[file:%s][%s]] | %s | [%s] |\n"
				      ffull
				      orgtitle
				      briefstring
				      tagstring)))
		  (insert entry)))
	      posts)
      (save-buffer))
    (oh/pandoc-to-html indx)
    t))

(oh/generate-files)
(oh/generate-index)

(require 'webfeeder)
(webfeeder-build
 "rss.xml"
 "./docs"
 "https://seungheonoh.github.com"
 (mapcar (lambda (s) (concat "posts/" s))
	   (directory-files "docs/posts/" nil "\\.html$"))
 :title "Blog"
 :description "Insert RSS Feed Here"
 :builder 'webfeeder-make-rss)

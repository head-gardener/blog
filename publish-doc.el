(require 'org)
(require 'ox-html)

(setq org-html-postamble
  (format "Keep your head up. Rev: %s." blog-rev))

(setq org-publish-project-alist
  '(("org"
     :auto-preamble t
     :base-directory "."
     :base-extension "org"
     :headline-levels 3
     :html-preamble t
     :auto-sitemap t
     :sitemap-filename "index.org"
     :sitemap-title "Sitemap"
     :publishing-directory "./build"
     :publishing-function org-html-publish-to-html
     :recursive t
     :section-numbers nil
     :with-toc nil
     :html-head "<link rel=\"stylesheet\"
             href=\"../static/styles.css\"
             type=\"text/css\"/>")))

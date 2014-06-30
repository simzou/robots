Per [Wikipedia](http://en.wikibooks.org/wiki/LaTeX/Bibliography_Management#Why_won.27t_LaTeX_generate_any_output.3F), the following commands need to be run to make the bibtex compile properly:

	pdflatex latex_source_code.tex
	bibtex latex_source_code.aux
	pdflatex latex_source_code.tex
	pdflatex latex_source_code.tex

These have been added to the Makefile so the command

	make

Should compile and produce the correct pdf

The style [plain-annote.bst](http://math.ucdenver.edu/~billups/courses/ma5779/annotated_bibliography.html) requires annotations be in the "annote" field of the .bib file.

The style annotate.bst (built in) requires annotations be in the "annotate" field of the .bib file

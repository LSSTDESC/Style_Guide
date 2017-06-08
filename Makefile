### User-settable options

# the base of the top-level .tex file to compile
PAPER ?= main

# set this to latex of pdflatex, whichever you want to use
LATEX ?= pdflatex

# set command to use for bibtexing
BIBTEX ?= bibtex

# set relative paths to figures, tables, bibiographic things, macros, etc. (not .)
# NB .tex files other than PAPER in the CWD are ignored, so use MACRODIR for them
FIGDIR ?= figures
TABDIR ?= tables
BIBDIR ?= bib
MACRODIR ?= macros

# instructions for creating BIBDIR
MAKEBIBDIR ?= 

# prefix for difference files
DIFPRE ?= diff_

# git repo branch to compare changes against
MASTERBRANCH ?= master





### automatically figure out what other files are important for various things

# get list of graphics files in FIGDIR
# add more formats in the FIGURES search if needed
# if we're pdflatexing but have eps figures, they will automatically be converted (below)
EPSFIGURES = $(shell ls $(FIGDIR)/*.eps 2>/dev/null)
ifeq ($(LATEX),pdflatex)
FIGURES = $(addsuffix .pdf,$(basename $(EPSFIGURES))) $(shell ls $(FIGDIR)/*.pdf $(FIGDIR)/*.png 2>/dev/null)
IGPDFS = $(FIGDIR)/*.pdf
endif

# misc
OTHERTEX = $(shell ls *.bib *.cls *.sty $(foreach f,$(BIBDIR),$(f)/*.*) $(foreach f,$(TABDIR),$(f)/*.*) $(foreach f,$(MACRODIR),$(f)/*.*) 2>/dev/null)



### set some more variables

# git repo branch we are compiling
THISBRANCH := $(shell git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/' | tr -d ' ')
# temp file for the version to compare against
DRAFT = $(PAPER).$(MASTERBRANCH)
# base for difference files to generate
DIFF = $(DIFPRE)$(THISBRANCH)


### fake targets
.PHONY: default bib clean diff gitignore detach $(PAPER)
# this ensures that the version to latexdiff against is always updated
.PHONY: $(DRAFT).tex

# if called with no target specified, compile the paper and the differences
# but skip the differences if we're on MASTERBRANCH currently, or not in a git repo at all
default: $(PAPER).pdf
ifneq ($(THISBRANCH),$(MASTERBRANCH))
ifneq ($(THISBRANCH),)
default: $(DIFF).pdf
endif
endif

$(PAPER): $(PAPER).pdf

diff: $(DIFF).pdf

clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc

gitignore: .gitignore


### rules!

$(BIBDIR):
	$(MAKEBIBDIR)

$(PAPER).pdf $(PAPER).aux $(PAPER).bbl $(PAPER).blg: $(PAPER).tex $(OTHERTEX) $(FIGURES)
	./maketex $< $(LATEX) $(BIBTEX)

$(DIFF).pdf: $(DIFF).tex $(OTHERTEX) $(FIGURES)
	./maketex $<

$(DIFF).tex: $(DRAFT).tex $(PAPER).tex
	latexdiff --exclude-textcmd="section,subsection,subsubsection,multicolumn" $^ > $@

$(DRAFT).tex:
	git show $(MASTERBRANCH):$(PAPER).tex > $@

%.pdf: %.eps
	epstopdf $<

.gitignore:
	echo "$(PAPER).pdf\n$(DRAFT).tex\n$(DIFPRE)*.tex\n*.aux\n*.bbl\n*.blg\n*.log\n*.out\n$(IGPDFS)" > $@

detach: .git
	rm -rf $<

# created 2023-01-15
# last modified 2023-01-19

export NATLANG ?= en-us

# these shd be in a separate file, and possibly deduced
export SEMESTER = fall
export YEAR = 2022

export TOPDIR := $(realpath .)

export PROGDIR := $(TOPDIR)/distribution/.prog-$(NATLANG)

export ADOCABLES_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adocables.rkt
export ADOC_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-asciidoctor.js
export ADOC_POSTPROC_LESSONPLAN_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-lessonplan.txt.kp
export ADOC_POSTPROC_NARRATIVEAUX_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-narrativeaux.txt.kp
export ADOC_POSTPROC_NARRATIVE_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-narrative.txt.kp
export ADOC_POSTPROC_RESOURCES_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-resources.txt.kp
export ADOC_POSTPROC_PWYINDEP_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-pwyindep.txt.kp
export ADOC_POSTPROC_WORKBOOKPAGE_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-adoc-postproc-workbookpage.txt.kp

export RELEVANT_LESSONS_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-relevant-lessons.txt.kp

export PUPPETEER_INPUT := $(TOPDIR)/distribution/$(NATLANG)/.cached/.do-puppeteer.json

export MAKE_DIR = lib/maker

all:
	$(MAKE) --no-print-directory -I $(MAKE_DIR) -f lib/maker/Makefile.phase1
	$(MAKE) --no-print-directory -I $(MAKE_DIR) -f lib/maker/Makefile.phase2
	$(MAKE) --no-print-directory -I $(MAKE_DIR) -f lib/maker/Makefile.phase3
	$(MAKE) --no-print-directory -I $(MAKE_DIR) -f lib/maker/Makefile.phase4
	$(MAKE) --no-print-directory -I $(MAKE_DIR) -f lib/maker/Makefile.phase5

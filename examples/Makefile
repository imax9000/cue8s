# Directories to render manifests from.
SUBDIRS := $(shell find . '(' -name base -o -name cue.mod -o -name '.?*' ')' -prune -o -type d -print | sed -e 's,^./,,' | grep -v '^\.$$' )

DIFF ?= diff -u

# If you have https://github.com/homeport/dyff installed:
# DIFF ?= dyff between --omit-header --color=on --output=human
export DIFF

export CUE_REGISTRY = imax.in.ua/cue8s=ghcr.io/imax9000/cue8s

include ./Makefile.default

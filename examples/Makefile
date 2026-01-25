# Directories to render manifests from.
DIRS := $(shell find . -maxdepth 1 -type d '!' '(' -name base -o -name cue.mod -o -name '.*' ')' | sed -e 's,^./,,')

DIFF ?= diff -u

# If you have https://github.com/homeport/dyff installed:
# DIFF ?= dyff between --omit-header --color=on --output=human


CODE_DIRS := $(shell find $(DIRS) -type f -name *.cue | while read f; do echo $$(dirname "$${f}"); done | sort -u)
MANIFESTS := $(CODE_DIRS:=/manifests.yaml)

BASE_FILES := cue.mod/module.cue $(wildcard base/*.cue base/**/*.cue)

export CUE_REGISTRY = imax.in.ua/cue8s=ghcr.io/imax9000/cue8s

# This is needed to ensure that `make print` output is coherent.
MAKEFLAGS := --output-sync=target

.PHONY: all fmt build diff
all: print

# Re-formats all CUE files.
fmt:
	cue fmt -s ./...

# Prints a YAML stream of rendered manifests to stdout.
print: $(CODE_DIRS:%=print-%)

# Writes out rendered manifests to manifests.yaml files.
build: $(MANIFESTS)

# Runs diff command against manifests.yaml files currently on disk and
# evaluated CUE files.
diff: $(CODE_DIRS:%=diff-%)


# `build` implementation
define src_deps =
$(1)/manifests.yaml: $$(wildcard $(1)/*.cue)
endef

$(foreach dir,$(CODE_DIRS),$(eval $(call src_deps,$(dir))))

$(MANIFESTS): %/manifests.yaml: $(BASE_FILES)

$(MANIFESTS): %/manifests.yaml:
	@time -f '%e\t%U\t%S\t%C' ./eval.sh $* > $@


# `print` implementation
.PHONY: $(CODE_DIRS:%=print-%)

$(CODE_DIRS:%=print-%): print-%:
	@time -f '%e\t%U\t%S\t%C' ./eval.sh $*
	@echo ---


# `diff` implementation
.PHONY: $(CODE_DIRS:%=diff-%)

$(CODE_DIRS:%=diff-%): diff-%:
	@./eval.sh $* | $(DIFF) $*/manifests.yaml -


# clean
.PHONY: clean
clean:
	rm $(MANIFESTS)

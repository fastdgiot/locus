REBAR3_URL=https://s3.amazonaws.com/rebar3/rebar3

ifeq ($(wildcard rebar3),rebar3)
	REBAR3 = $(CURDIR)/rebar3
endif

ifdef RUNNING_ON_CI
REBAR3 = ./rebar3
else
REBAR3 ?= $(shell test -e `which rebar3` 2>/dev/null && which rebar3 || echo "./rebar3")
endif

ifeq ($(REBAR3),)
	REBAR3 = $(CURDIR)/rebar3
endif

CLI_ARTIFACT_PATH = _build/escriptize/bin/locus

.PHONY: all build clean check
.PHONY: xref hank-dead-code-cleaner elvis-linter dialyzer
.PHONY: test cover
.PHONY: shell console doc publish cli

.NOTPARALLEL: check cover test

all: build

build: $(REBAR3)
	@$(REBAR3) compile

$(REBAR3):
	wget $(REBAR3_URL) || curl -Lo rebar3 $(REBAR3_URL)
	@chmod a+x rebar3

clean: $(REBAR3)
	@$(REBAR3) clean

check: xref hank-dead-code-cleaner elvis-linter dialyzer

xref: $(REBAR3)
	@$(REBAR3) xref

hank-dead-code-cleaner: $(REBAR3)
	@$(REBAR3) hank

elvis-linter: $(REBAR3)
	@$(REBAR3) lint

dialyzer: $(REBAR3)
	@$(REBAR3) dialyzer

test: $(REBAR3) cli
	@$(REBAR3) do eunit, ct, cover
	./locus check --log-level debug test/priv/GeoLite2-Country.tar.gz

cover: test

shell: export ERL_FLAGS = +pc unicode
shell:
	@$(REBAR3) as shell shell

console: shell

doc: $(REBAR3)
	./support/scripts/generate_docs.sh

publish: $(REBAR3)
publish: doc
	@$(REBAR3) hex publish

cli: $(REBAR3)
	@$(REBAR3) as escriptize escriptize
	cp -p "$(CLI_ARTIFACT_PATH)" ./

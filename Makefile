JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
DASHBOARDS_DIR := dashboards_out
ALERTS_DIR := alerts_out
RULES_DIR := rules_out

# Static dashboard manifest
STATIC_MANIFEST := dashboards-static/manifest.json

# Helper to get mixin list from jsonnet (requires vendor/)
MIXIN_ARTIFACTS = $(shell jsonnet -J vendor -S -e 'std.join("\n", std.objectFields(import "lib/mixins.libsonnet"))' 2>/dev/null)

.PHONY: all clean generate vendor dashboards dashboards-static alerts rules fmt

all: generate

vendor: jsonnetfile.json
	jb install

generate: vendor
	@$(MAKE) dashboards dashboards-static alerts rules

dashboards: vendor
	@for artifact in $(MIXIN_ARTIFACTS); do mkdir -p $(DASHBOARDS_DIR)/$$artifact; done
	jsonnet -J vendor -m $(DASHBOARDS_DIR) lib/dashboards.jsonnet

dashboards-static:
	@for artifact in $$(jq -r 'keys[]' $(STATIC_MANIFEST)); do \
		mkdir -p $(DASHBOARDS_DIR)/$$artifact; \
		for file in $$(jq -r ".\"$$artifact\".files[]" $(STATIC_MANIFEST)); do \
			cp dashboards-static/$$file $(DASHBOARDS_DIR)/$$artifact/; \
		done; \
	done

alerts: vendor
	@for artifact in $(MIXIN_ARTIFACTS); do \
		mkdir -p $(ALERTS_DIR)/$$artifact; \
		output=$$(jsonnet -J vendor -S --ext-str mixin=$$artifact lib/alerts.jsonnet); \
		if [ -n "$$output" ]; then \
			echo "$$output" > $(ALERTS_DIR)/$$artifact/alerts.yml; \
			echo "$(ALERTS_DIR)/$$artifact/alerts.yml"; \
		fi; \
	done

rules: vendor
	@for artifact in $(MIXIN_ARTIFACTS); do \
		mkdir -p $(RULES_DIR)/$$artifact; \
		output=$$(jsonnet -J vendor -S --ext-str mixin=$$artifact lib/rules.jsonnet); \
		if [ -n "$$output" ]; then \
			echo "$$output" > $(RULES_DIR)/$$artifact/rules.yml; \
			echo "$(RULES_DIR)/$$artifact/rules.yml"; \
		fi; \
	done

fmt:
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

clean:
	rm -rf $(DASHBOARDS_DIR) $(ALERTS_DIR) $(RULES_DIR) vendor

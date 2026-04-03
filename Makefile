JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
OUT_DIR := dashboards_out

# Mixin artifacts (subdirectories created before jsonnet build)
MIXIN_ARTIFACTS := \
	alertmanager-mixin \
	grafana-mixin \
	kubernetes-mixin \
	loki-mixin \
	node-exporter-mixin \
	prometheus-mixin

# Static dashboard mapping: artifact:file1,file2,...
STATIC_MAP := \
	flux:flux-cluster.json,flux-control-plane.json,flux-logs.json \
	longhorn:longhorn.json \
	k8up:k8up.json

.PHONY: all clean generate vendor dashboards dashboards-static alerts rules fmt

all: generate

vendor: jsonnetfile.json
	jb install

generate: vendor dashboards dashboards-static alerts rules

dashboards: vendor
	@for artifact in $(MIXIN_ARTIFACTS); do mkdir -p $(OUT_DIR)/$$artifact; done
	jsonnet -J vendor -m $(OUT_DIR) lib/dashboards.jsonnet

dashboards-static:
	@for entry in $(STATIC_MAP); do \
		component=$${entry%%:*}; \
		files=$${entry#*:}; \
		mkdir -p $(OUT_DIR)/$$component; \
		for file in $$(echo $$files | tr ',' ' '); do \
			cp dashboards-static/$$file $(OUT_DIR)/$$component/; \
		done; \
	done

alerts: vendor
	@mkdir -p out
	jsonnet -J vendor -S lib/alerts.jsonnet > out/alerts.yaml

rules: vendor
	@mkdir -p out
	jsonnet -J vendor -S lib/rules.jsonnet > out/rules.yaml

fmt:
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

clean:
	rm -rf $(OUT_DIR) out vendor

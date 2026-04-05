// Single source of truth for all mixin imports.
// Add or remove mixins here — dashboards, alerts, and rules all reference this file.

local sharedConfig = import 'config.libsonnet';
local withConfig(mixin) = mixin + { _config+:: sharedConfig };

{
  'kubernetes-mixin': withConfig(import 'kubernetes-mixin/mixin.libsonnet'),
  'grafana-mixin': withConfig(import 'grafana-mixin/mixin.libsonnet'),
  'prometheus-mixin': withConfig(import 'prometheus-mixin/mixin.libsonnet'),
  'node-exporter-mixin': withConfig(import 'node-mixin/mixin.libsonnet'),
  'alertmanager-mixin': withConfig(import 'alertmanager-mixin/mixin.libsonnet'),
  // loki-mixin: dashboards disabled — designed for microservices/SSD mode,
  // incompatible with single-binary Loki scraped via OTel.
  // Alerts and rules kept — they use simple job/cluster grouping that works.
  // See: https://github.com/grafana/loki/issues/4838
  'loki-mixin': withConfig(import 'loki-mixin/mixin.libsonnet') {
    grafanaDashboards:: {},
  },
  'kube-state-metrics-mixin': withConfig(import 'kube-state-metrics-mixin/mixin.libsonnet'),
}

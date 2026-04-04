// Generates recording rules for a single mixin.
// Called with --ext-str mixin=<name> to select which mixin to build.
// Use -S flag for string output (YAML).

local sharedConfig = import 'config.libsonnet';
local withConfig(mixin) = mixin + { _config+:: sharedConfig };
local mixinName = std.extVar('mixin');

local mixins = {
  'kubernetes-mixin': withConfig(import 'kubernetes-mixin/mixin.libsonnet'),
  'grafana-mixin': withConfig(import 'grafana-mixin/mixin.libsonnet'),
  'prometheus-mixin': withConfig(import 'prometheus-mixin/mixin.libsonnet'),
  'node-exporter-mixin': withConfig(import 'node-mixin/mixin.libsonnet'),
  'alertmanager-mixin': withConfig(import 'alertmanager-mixin/mixin.libsonnet'),
  'loki-mixin': withConfig(import 'loki-mixin/mixin.libsonnet'),
  'kube-state-metrics-mixin': withConfig(import 'kube-state-metrics-mixin/mixin.libsonnet'),
};

if std.objectHasAll(mixins[mixinName], 'prometheusRules')
then std.manifestYamlDoc(mixins[mixinName].prometheusRules)
else ''

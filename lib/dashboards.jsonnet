// Generates dashboards per mixin.
// Output keys use "mixin-name/dashboard-name.json" so jsonnet -m writes
// to subdirectories matching the OCI artifact names.
//
// All dashboards are included — filtering is the consumer's responsibility.

local config = import '../mixin.libsonnet';
local withConfig(mixin) = mixin + { _config+:: config._config };

local mixins = {
  'kubernetes-mixin':
    withConfig(import 'kubernetes-mixin/mixin.libsonnet').grafanaDashboards,
  'grafana-mixin':
    withConfig(import 'grafana-mixin/mixin.libsonnet').grafanaDashboards,
  'prometheus-mixin':
    withConfig(import 'prometheus-mixin/mixin.libsonnet').grafanaDashboards,
  'node-exporter-mixin':
    withConfig(import 'node-mixin/mixin.libsonnet').grafanaDashboards,
  'alertmanager-mixin':
    withConfig(import 'alertmanager-mixin/mixin.libsonnet').grafanaDashboards,
  'loki-mixin':
    withConfig(import 'loki-mixin/mixin.libsonnet').grafanaDashboards,
};

{
  [mixin + '/' + name]: mixins[mixin][name]
  for mixin in std.objectFields(mixins)
  for name in std.objectFields(mixins[mixin])
}

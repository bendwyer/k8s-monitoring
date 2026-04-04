// Generates dashboards per mixin.
// Output keys use "mixin-name/dashboard-name.json" so jsonnet -m writes
// to subdirectories matching the OCI artifact names.
//
// All dashboards are included — filtering is the consumer's responsibility.
//
// Each mixin is imported independently and only receives the shared config
// overrides (selectors, cluster label, etc.). This prevents config fields
// like dashboardTags from bleeding between mixins.

local sharedConfig = import 'config.libsonnet';

local withConfig(mixin) = mixin + { _config+:: sharedConfig };

// Default tags to mixin name if the dashboard has no tags
local ensureTags(mixin, dashboard) =
  if std.objectHas(dashboard, 'tags') && std.length(dashboard.tags) > 0
  then dashboard
  else dashboard + { tags: [mixin] };

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
  [mixin + '/' + name]: ensureTags(mixin, mixins[mixin][name])
  for mixin in std.objectFields(mixins)
  for name in std.objectFields(mixins[mixin])
}

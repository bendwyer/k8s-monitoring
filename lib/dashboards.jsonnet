// Generates dashboards per mixin.
// Output keys use "mixin-name/dashboard-name.json" so jsonnet -m writes
// to subdirectories matching the OCI artifact names.
//
// All dashboards are included — filtering is the consumer's responsibility.
//
// Each mixin is imported independently and only receives the shared config
// overrides (selectors, cluster label, etc.). This prevents config fields
// like dashboardTags from bleeding between mixins.

local mixins = import 'mixins.libsonnet';

// Default tags to mixin name if the dashboard has no tags
local ensureTags(mixin, dashboard) =
  if std.objectHas(dashboard, 'tags') && std.length(dashboard.tags) > 0
  then dashboard
  else dashboard + { tags: [mixin] };

{
  [mixin + '/' + name]: ensureTags(mixin, mixins[mixin].grafanaDashboards[name])
  for mixin in std.objectFields(mixins)
  if std.objectHasAll(mixins[mixin], 'grafanaDashboards')
  for name in std.objectFields(mixins[mixin].grafanaDashboards)
}

// Single source of truth for all mixin imports.
// Add or remove mixins here — dashboards, alerts, and rules all reference this file.

local sharedConfig = import 'config.libsonnet';
local withConfig(mixin) = mixin + { _config+:: sharedConfig };

// Workaround: the opentelemetry-collector-mixin (pinned at 2025-10-23) references
// pre-rename gRPC metric names (e.g. rpc_server_duration_milliseconds_bucket).
// The collector at v0.151+ emits the post-rename names (rpc_server_call_duration_seconds_bucket).
// Substitute query strings via regex broadening so the gRPC Network-traffic panels
// match either name. Panel units are already seconds/bytes so no scaling needed.
// Track upstream: https://github.com/grafana/jsonnet-libs (no per-mixin issue tracker yet).
local rewriteQueryString(s) =
  local replacements = [
    ['rpc_server_duration_milliseconds_bucket', 'rpc_server(_call)?_duration_(milli)?seconds_bucket'],
    ['rpc_client_duration_milliseconds_bucket', 'rpc_client(_call)?_duration_(milli)?seconds_bucket'],
    ['rpc_server_request_size_bytes_bucket', 'rpc_server(_call)?_request_size_bytes_bucket'],
    ['rpc_client_request_size(_bytes_?)_bucket', 'rpc_client(_call)?_request_size_bytes_bucket'],
  ];
  std.foldl(
    function(acc, pair) std.strReplace(acc, pair[0], pair[1]),
    replacements,
    s
  );
local rewriteTarget(t) =
  if std.objectHas(t, 'expr') then t { expr: rewriteQueryString(t.expr) } else t;
local rewritePanel(p) =
  p + (if std.objectHas(p, 'targets')
       then { targets: [rewriteTarget(t) for t in p.targets] }
       else {});
local rewriteDashboard(d) =
  d + (if std.objectHas(d, 'panels')
       then { panels: [rewritePanel(p) for p in d.panels] }
       else {});
local fixOtelMetricDrift(mixin) = mixin {
  grafanaDashboards+:: {
    [name]: rewriteDashboard(super[name])
    for name in std.objectFields(super.grafanaDashboards)
  },
};

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
  'opentelemetry-collector-mixin': fixOtelMetricDrift(
    withConfig(import 'opentelemetry-collector-mixin/mixin.libsonnet')
  ),
  'claude-code-mixin': withConfig(import 'claude-code-mixin/mixin.libsonnet'),
}

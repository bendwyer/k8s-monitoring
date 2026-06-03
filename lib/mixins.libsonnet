// Single source of truth for all mixin imports.
// Add or remove mixins here — dashboards, alerts, and rules all reference this file.

local sharedConfig = import 'config.libsonnet';
local withConfig(mixin) = mixin { _config+:: sharedConfig };

// snmp-observ-lib is a parameterized library (not a ready-made mixin), so it is
// instantiated rather than imported with withConfig. metricsSource picks the
// vendor signal sets (generic if_mib + MikroTik health). Loki log panels are
// disabled: they expect sysname/syslog_app_name/level labels, which the cluster's
// syslog stream (service_name/detected_level) does not carry.
local snmpObservLib = import 'snmp-observ-lib/main.libsonnet';
// Workaround: with metricsSource lacking 'cisco', the Cisco FRU alert
// (cefcFRUPowerOperStatus) renders with an empty `({ }) == 1` selector, which is
// invalid PromQL and would fail the whole rule group load. Drop any alert rule
// whose expr contains an empty `{ }` matcher.
local dropEmptySelectorAlerts(mixin) = mixin {
  prometheusAlerts+:: {
    groups: [
      g {
        rules: [
          r
          for r in g.rules
          if !(std.objectHas(r, 'expr') && std.length(std.findSubstr('{ }', r.expr)) > 0)
        ],
      }
      for g in mixin.prometheusAlerts.groups
    ],
  },
};
local snmpMixin = dropEmptySelectorAlerts(
  (snmpObservLib.new() + snmpObservLib.withConfigMixin({
     // Match all SNMP scrape jobs (snmp-mikrotik today, snmp-<device> later) rather
     // than one job, so the mixin covers every SNMP device. A non-empty selector
     // also keeps the "target down" alert (up{...}==0), which the lib omits when the
     // selector is empty since a bare up==0 would match every target in the cluster.
     filteringSelector: 'job=~"snmp.*"',
     metricsSource: ['generic', 'mikrotik'],
     enableLokiLogs: false,
   })).asMonitoringMixin()
);

// Workaround: the opentelemetry-collector-mixin (pinned at 2025-10-23) references
// pre-rename OTel metric names that no longer match the cluster's emission. The
// collector at v0.152.0+ renamed `rpc_*_duration` → `rpc_*_call_duration` (semconv
// 1.27) and dropped unit suffixes (`_seconds`, `_bytes`, `_milliseconds`) while
// keeping `_total` on counters. Rewrite the pre-rename names to the current
// emission. Track upstream: https://github.com/grafana/jsonnet-libs.
local rewriteQueryString(s) =
  local replacements = [
    ['rpc_server_duration_milliseconds_bucket', 'rpc_server_call_duration_bucket'],
    ['rpc_client_duration_milliseconds_bucket', 'rpc_client_call_duration_bucket'],
    ['rpc_server_request_size_bytes_bucket', 'rpc_server_request_size_bucket'],
    ['rpc_client_request_size(_bytes_?)_bucket', 'rpc_client_request_size_bucket'],
    ['otelcol_process_uptime(_seconds_total)?', 'otelcol_process_uptime_total'],
    ['http_server_request_duration_seconds_bucket', 'http_server_request_duration_bucket'],
    ['http_client_request_duration_seconds_bucket', 'http_client_request_duration_bucket'],
    ['http_server_request_body_size_bytes_bucket', 'http_server_request_body_size_bucket'],
    ['http_client_request_body_size_bytes_bucket', 'http_client_request_body_size_bucket'],
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
// The upstream mixin passes the bare metric name `otelcol_process_uptime` into
// commonlib.variables.new, which renders `label_values(otelcol_process_uptime{...}, ...)`
// for the $job and $instance dropdowns. Substitute to the current emission name
// so the dropdowns populate. Panel queries are handled by rewriteQueryString above.
local rewriteUptimeVarQuery(q) =
  if std.isString(q)
  then std.strReplace(q, 'otelcol_process_uptime{', 'otelcol_process_uptime_total{')
  else q;
local rewriteUptimeVariable(v) =
  if std.objectHas(v, 'query')
  then v { query: rewriteUptimeVarQuery(v.query) }
  else v;
local rewriteUptimeTemplating(t) =
  t + (if std.objectHas(t, 'list')
       then { list: [rewriteUptimeVariable(v) for v in t.list] }
       else {});
local rewriteDashboard(d) =
  d + (if std.objectHas(d, 'panels')
       then { panels: [rewritePanel(p) for p in d.panels] }
       else {})
  + (if std.objectHas(d, 'templating')
     then { templating: rewriteUptimeTemplating(d.templating) }
     else {});
local fixOtelMetricDrift(mixin) = mixin {
  grafanaDashboards+:: {
    [name]: rewriteDashboard(super[name])
    for name in std.objectFields(super.grafanaDashboards)
  },
};

// Workaround: the claude-code-mixin's $job variable has allValue=".+" which
// matches every target_info series in Prometheus, not just Claude Code's.
// Tighten the All-value regex so "All" matches only the bare `claude-code`
// job plus any `<prefix>/claude-code` variants (a prefix appears when an
// upstream processor injects service.namespace into the metrics).
local rewriteJobVariable(v) =
  if std.objectHas(v, 'name') && v.name == 'job' then
    v { allValue: '(?:.*/)?claude-code' }
  else v;
local rewriteTemplating(t) =
  t + (if std.objectHas(t, 'list')
       then { list: [rewriteJobVariable(v) for v in t.list] }
       else {});
local rewriteDashboardJobDefault(d) =
  d + (if std.objectHas(d, 'templating')
       then { templating: rewriteTemplating(d.templating) }
       else {});
local tightenClaudeCodeAllValue(mixin) = mixin {
  grafanaDashboards+:: {
    [name]: rewriteDashboardJobDefault(super[name])
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
  'claude-code-mixin': tightenClaudeCodeAllValue(
    withConfig(import 'claude-code-mixin/mixin.libsonnet')
  ),
  'snmp-mixin': snmpMixin,
}

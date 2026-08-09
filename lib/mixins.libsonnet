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
local snmpConfig = {
  // Match all SNMP scrape jobs (snmp-mikrotik today, snmp-<device> later) rather than
  // one job, so the mixin covers every SNMP device. A non-empty selector also keeps the
  // "target down" alert (up{...}==0), which the lib omits when the selector is empty
  // since a bare up==0 would match every target in the cluster.
  filteringSelector: 'job=~"snmp.*"',
  metricsSource: ['generic', 'mikrotik'],
  enableLokiLogs: false,
};
local snmpRaw = snmpObservLib.new() + snmpObservLib.withConfigMixin(snmpConfig);

local snmpMixin = dropEmptySelectorAlerts(snmpRaw.asMonitoringMixin());

// Workaround: the claude-code-mixin's $job variable has allValue=".+", and the
// panels select target_info{job=~"$job"}. target_info carries every OTLP source
// in the cluster, so "All" pulls in unrelated jobs (snmp-mikrotik and the OTel
// collectors' own telemetry today). Pin the All-value to this mixin's own job.
//
// It used to also allow a `<prefix>/claude-code` form, which appeared when a
// collector injected service.namespace into the metrics. Nothing does that now
// that the application OTLP path terminates on Alloy, so the prefix is dropped
// rather than carried: if one ever reappears, the empty panel should point at
// whatever started injecting it.
local rewriteJobVariable(v) =
  if std.objectHas(v, 'name') && v.name == 'job' then
    v { allValue: 'claude-code' }
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
  'loki-mixin': withConfig(import 'loki-mixin/mixin.libsonnet') {
    _config+:: {
      blooms: { enabled: false },
      thanos: { enabled: false },
      promtail: { enabled: false },
      operational+: {
        memcached: false,
        consul: false,
        bigTable: false,
        dynamo: false,
        gcs: false,
        s3: false,
        azureBlob: false,
        boltDB: false,
      },
    },
  },
  'kube-state-metrics-mixin': withConfig(import 'kube-state-metrics-mixin/mixin.libsonnet'),
  // alloy-mixin: the default cluster/namespace selector is left alone because the
  // collectors label their own self-metrics with namespace and pod. enableAlloyCluster
  // is back at its default of true now that alloy-singleton runs clustered; every
  // clustering alert joins on cluster_node_info, which the unclustered alloy-node
  // never emits, so those alerts scope themselves rather than needing a selector.
  // logsFilterSelector matches on the container name, which is what Loki derives
  // service_name from, so it is "alloy" for every collector rather than the
  // component name.
  'alloy-mixin': withConfig(import 'alloy-mixin/mixin.libsonnet') {
    _config+:: {
      logsFilterSelector: 'service_name="alloy"',
    },
  },
  'claude-code-mixin': tightenClaudeCodeAllValue(
    withConfig(import 'claude-code-mixin/mixin.libsonnet')
  ),
  'snmp-mixin': snmpMixin,
}

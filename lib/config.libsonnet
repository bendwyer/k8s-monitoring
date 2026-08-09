// Shared config overrides applied to all mixins individually.
// This prevents config fields like dashboardTags from bleeding between mixins.
{
  clusterLabel: 'cluster',
  grafanaDatasourceName: 'Prometheus',
  datasourceName: 'Prometheus',
  // Only selectors that genuinely differ from the mixin's own default belong here.
  // Seven others (kubelet, kube-state-metrics, kube-scheduler, kube-controller-manager,
  // kube-proxy, alertmanager, prometheus) restated their defaults verbatim and were
  // removed after confirming the generated dashboards, alerts and rules were byte
  // identical without them. Before adding one, check the mixin's config.libsonnet:
  // the scrape job should be renamed to match the default in preference to overriding.
  //
  // The two below are the collector's job names differing from what the mixin expects,
  // and both should be resolved by renaming the Alloy scrape job rather than kept.
  cadvisorSelector: 'job="kubelet"',  // mixin default is job="cadvisor"
  kubeApiserverSelector: 'job="apiserver"',  // mixin default is job="kube-apiserver"

  // Unavoidable: kubernetes-mixin defaults to job="node-exporter" and node-exporter-mixin
  // to job="node", so one of the two needs telling either way. Ours matches the former.
  nodeExporterSelector: 'job="node-exporter"',

  showMultiCluster: false,

  // Defaults (40/20) fire during normal disk reclaim cycles.
  fsSpaceFillingUpWarningThreshold: 15,
  fsSpaceFillingUpCriticalThreshold: 10,
}

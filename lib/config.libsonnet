// Shared config overrides applied to all mixins individually.
// This prevents config fields like dashboardTags from bleeding between mixins.
{
  clusterLabel: 'cluster',
  grafanaDatasourceName: 'Prometheus',
  datasourceName: 'Prometheus',
  cadvisorSelector: 'job="kubelet"',
  kubeletSelector: 'job="kubelet"',
  kubeStateMetricsSelector: 'job="kube-state-metrics"',
  nodeExporterSelector: 'job="node-exporter"',
  kubeApiserverSelector: 'job="apiserver"',
  kubeSchedulerSelector: 'job="kube-scheduler"',
  kubeControllerManagerSelector: 'job="kube-controller-manager"',
  kubeProxySelector: 'job="kube-proxy"',
  alertmanagerSelector: 'job="alertmanager"',
  prometheusSelector: 'job="prometheus"',
  showMultiCluster: false,

  // Defaults (40/20) fire during normal disk reclaim cycles.
  fsSpaceFillingUpWarningThreshold: 15,
  fsSpaceFillingUpCriticalThreshold: 10,
}

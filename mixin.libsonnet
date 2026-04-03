// Import all monitoring mixins
(import 'kubernetes-mixin/mixin.libsonnet') +
(import 'node-mixin/mixin.libsonnet') +
(import 'prometheus-mixin/mixin.libsonnet') +
(import 'alertmanager-mixin/mixin.libsonnet') +
(import 'loki-mixin/mixin.libsonnet') +
(import 'grafana-mixin/mixin.libsonnet') +
(import 'kube-state-metrics-mixin/mixin.libsonnet') +

// Custom configuration overrides
{
  _config+:: {
    // Cluster label added by OTel Collector prometheusremotewrite exporter
    clusterLabel: 'cluster',

    // Grafana datasource name (must match the provisioned datasource)
    grafanaDatasourceName: 'Prometheus',

    // cadvisor metric source — scraped by OTel Gateway via kubelet
    cadvisorSelector: 'job="kubelet"',
    kubeletSelector: 'job="kubelet"',

    // kube-state-metrics — scraped by OTel Gateway
    kubeStateMetricsSelector: 'job="kube-state-metrics"',

    // node-exporter — scraped by OTel Gateway
    nodeExporterSelector: 'job="node-exporter"',

    // Control plane components — scraped by OTel Gateway
    kubeApiserverSelector: 'job="apiserver"',

    // Not scraping scheduler/controller-manager/proxy/etcd
    kubeSchedulerSelector: 'job="kube-scheduler"',
    kubeControllerManagerSelector: 'job="kube-controller-manager"',
    kubeProxySelector: 'job="kube-proxy"',

    // Alertmanager
    alertmanagerSelector: 'job="alertmanager"',

    // Prometheus
    prometheusSelector: 'job="prometheus"',

    // Disable multi-cluster features
    showMultiCluster: false,
  },
}

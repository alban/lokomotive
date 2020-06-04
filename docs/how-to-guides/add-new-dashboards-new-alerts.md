# Add Custom Monitoring Configs

## Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Add Custom Grafana Dashboards](#add-custom-grafana-dashboards)
* [Add new Service Monitors](#add-new-service-monitors)
  * [Default Prometheus Operator setting](#default-prometheus-operator-setting)
  * [Custom Prometheus Operator setting:](#custom-prometheus-operator-setting)
* [Add Custom Alerts for Alertmanager](#add-custom-alerts-for-alertmanager)
  * [Default Prometheus Operator setting](#default-prometheus-operator-setting-1)
  * [Custom Prometheus Operator setting:](#custom-prometheus-operator-setting-1)
* [Additional resources](#additional-resources)

## Introduction

This guide will take you through the steps of adding custom grafana dashboards custom alert manager rules.

## Prerequisites

- The component prometheus-operator deployed on a Lokomotive cluster.

## Add Custom Grafana Dashboards

Create a Configmap with key as the dashboard file name and value as JSON dashboard, e.g.:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dashboard
  labels:
    grafana_dashboard: "true"
data:
  metallb.json: |
    {
      "annotations": {
[REDACTED]
```

Make sure that you add the label `grafana_dashboard: "true"` so that grafana automatically picks up the dashboards in the Configmaps all over the cluster.


## Add new Service Monitors

#### Default Prometheus Operator setting:

Create a ServiceMonitor with the required configuration and make sure to add the following label, so that the prometheus-operator will track it:

```yaml
metadata:
  labels:
    release: prometheus-operator
```

#### Custom Prometheus Operator setting:

If you have deployed the prometheus-operator with following setting, which makes sure that the prometheus-operator watches all ServiceMonitors in all namespaces:

```tf
watch_labeled_service_monitors = "false"
```

Then you don't need to add any label to ServiceMonitor, at all. Just create a ServiceMonitor and it will be tracked by prometheus-operator.

## Add Custom Alerts for Alertmanager

#### Default Prometheus Operator setting:

Create a PrometheuRule object with the required configuration and make sure to add the following labels, so that prometheus-operator will track it:

```yaml
metadata:
  labels:
    release: prometheus-operator
    app: prometheus-operator
```

#### Custom Prometheus Operator setting:

If you have deployed the prometheus-operator with following setting, which makes sure that the prometheus-operator watches all PrometheusRules in all namespaces:

```tf
watch_labeled_prometheus_rules = "false"
```

Then you don't need to add any label to PrometheusRule, at all. Just create a PrometheusRule and it will be tracked by the prometheus-operator.

## Additional resources

- Service Monitor API docs https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitor
- PrometheusRule API docs https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusrule

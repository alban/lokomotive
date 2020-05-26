# Access Monitoring on Lokomotive

## Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Prometheus](#prometheus)
* [Alertmanager](#alertmanager)
* [Grafana](#grafana)
  * [Using Port Forward](#using-port-forward)
  * [Using Ingress](#using-ingress)

## Introduction

You can deploy the monitoring stack shipped with lokomotive as shown in the prometheus-operator component [guide](../configuration-reference/components/prometheus-operator.md).

## Prerequisites

- The prometheus-operator component is deployed in `monitoring` Namespace. If you have specified a different Namespace in config then change the commands accordingly, `kubectl -n <your namespace> ...`.

## Prometheus

Execute the command to port forward prometheus locally on port `9090`:

```
kubectl -n monitoring port-forward svc/prometheus-operator-prometheus 9090:9090
```

Now open the following URL: [http://localhost:9090](http://localhost:9090).

## Alertmanager

Run the following command to port forward alertmanager locally on port `9093`.

```
kubectl -n monitoring port-forward svc/prometheus-operator-alertmanager 9093:9093
```

Now open the following URL: [http://localhost:9093](http://localhost:9093).

## Grafana

### Using Port Forward

Run the following command to port forward grafana dashboard locally on port `8080`.

```
kubectl -n monitoring port-forward svc/prometheus-operator-grafana 8080:80
```

Obtain grafana `admin` user password by running following command:

```
kubectl -n monitoring get secret prometheus-operator-grafana -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

Now open the following URL: [http://localhost:8080](http://localhost:8080). Enter username `admin` and password obtained from previous step.

### Using Ingress

Make sure you are using a configuration for grafana in prometheus-operator something similar to following:

```tf
component "prometheus-operator" {
  grafana {
    ingress {
      host = "grafana.mydomain.com"
    }
  }
}
```

**NOTE**: If you are running this component on Packet then make sure that you have made a DNS entry for `grafana.mydomain.com` against the Packet EIP.


Obtain grafana `admin` user password by running following command:

```
kubectl -n monitoring get secret prometheus-operator-grafana -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

Now open the following URL: https://grafana.mydomain.com (replace this URL with your domain). Enter username `admin` and password obtained from previous step.

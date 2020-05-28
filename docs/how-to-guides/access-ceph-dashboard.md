# Accessing Ceph Dashboard

## Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Steps](#steps)
* [Additional resources](#additional-resources)

## Introduction

Ceph deployed using the rook component comes with its own dashboard. This guide will walk you through the steps to follow to access the dashboard locally.

## Prerequisites

- The guide assumes that you have deployed the _rook_ and _rook-ceph_ component in the `rook` namespace. If that is not the case then change the commands to use the correct namespace.

## Steps:

### Step 1: Port forward the service locally

```
kubectl -n rook port-forward svc/rook-ceph-mgr-dashboard 8443:8443
```

### Step 2: Find the admin password

```
kubectl -n rook get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

### Step 3: Access via browser

Now goto [https://localhost:8443](https://localhost:8443) and enter username `admin` and password obtained from the previous step.

## Additional resources

- Read more detailed information on ceph dashboard on [rook docs](https://rook.io/docs/rook/master/ceph-dashboard.html).

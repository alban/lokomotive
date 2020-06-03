# CSI Driver for Amazon EBS configuration reference for Lokomotive

## Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Configuration](#configuration)
* [Attribute reference](#attribute-reference)
* [Applying](#applying)
* [Deleting](#deleting)

## Introduction

The [CSI Driver for Amazon EBS](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
provides a CSI interface used by Container Orchestrators to manage the lifecycle
of Amazon EBS volumes. It provides a storage class for AWS, baked by Amazon EBS
volumes.

## Prerequisites

* A Lokomotive cluster accessible via `kubectl` deployed on Packet.

## Configuration

To run a cluster with the CSI Driver component, `set_csi_driver_iam_role` needs
to be set to true in the `cluster` block of your lokocfg. The flag and the component
should only be used for clusters deployed on AWS.

CSI Driver component configuration example:

```tf
# aws-ebs-csi-driver.lokocfg
component "aws-ebs-csi-driver" {
    enable_default_storage_class = true
}
```

## Attribute reference

Table of all the arguments accepted by the component.

Example:

| Argument                       | Description                                                  | Default      | Required |
|--------------------------------|--------------------------------------------------------------|:------------:|:--------:|
| `enable_default_storage_class` | Use the default storage class provided by the component      | true         | false    |

## Applying

To apply the CSI Driver component:

```bash
lokoctl component apply aws-ebs-csi-driver
```
By default, the CSI Driver pods run in the `kube-system` namespace.

## Deleting

To destroy the component:

```bash
lokoctl component delete aws-ebs-csi-driver
```

When destroying the cluster or deleting the component, EBS volumes must be cleaned up
manually.
# How to setup third party OAuth for Grafana?

## Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Steps](#steps)
* [What's next?](#whats-next)

## Introduction

This document will help you to enable any supported auth provider on Grafana deployed as a part of Prometheus Operator.

## Prerequisites

- On Packet: You have a DNS entry in any DNS provider for `grafana.mydomain.net` against the Packet EIP.
- On AWS: You don't have to make any special DNS entries. Just make sure that the `grafana.ingress.host` value is `grafana.<CLUSTER NAME>.<AWS DNS ZONE>`.

## Steps

**NOTE**: This guide assumes that the underlying cloud platform is Packet and the OAuth provider is Github. For other OAuth providers the steps are the same just the secret parameters will change as mentioned in [Step 3](#step-3).

#### Step 1

- Create a Github OAuth application as documented in [Grafana docs](https://grafana.com/docs/grafana/latest/auth/github/).
- Set the **Homepage URL** to https://grafana.mydomain.net. It will also be set as environment variable `GF_SERVER_ROOT_URL` in [Step 3](#step-3).
- Set the **Authorization callback URL** to https://grafana.mydomain.net/login/github.
- Make a note of `Client ID` and `Client Secret` it will be needed in [Step 3](#step-3) and set as environment variable `GF_AUTH_GITHUB_CLIENT_ID` and `GF_AUTH_GITHUB_CLIENT_SECRET` respectively.

#### Step 2

Create `prometheus-operator.lokocfg` file with following contents:

```tf
component "prometheus-operator" {
  namespace = "monitoring"

  grafana {
    env_from_secret = "githuboauth"
    ingress {
      host = "grafana.mydomain.net"
    }
  }
}
```

Observe the value of variable `env_from_secret` it should match the name of secret to be created in [Step 3](#step-3).

Deploy the prometheus operator using following command:

```bash
lokoctl component apply prometheus-operator
```

#### Step 3

Populate values of the following secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: githuboauth
  namespace: monitoring
type: Opaque
stringData:
  GF_SERVER_ROOT_URL: https://grafana.mydomain.net
  # env vars for github oauth provider
  GF_AUTH_GITHUB_ENABLED: "true"
  GF_AUTH_GITHUB_ALLOW_SIGN_UP: "true"
  GF_AUTH_GITHUB_CLIENT_ID: YOUR_GITHUB_APP_CLIENT_ID
  GF_AUTH_GITHUB_CLIENT_SECRET: YOUR_GITHUB_APP_CLIENT_SECRET
  GF_AUTH_GITHUB_SCOPES: user:email,read:org
  GF_AUTH_GITHUB_AUTH_URL: https://github.com/login/oauth/authorize
  GF_AUTH_GITHUB_TOKEN_URL: https://github.com/login/oauth/access_token
  GF_AUTH_GITHUB_API_URL: https://api.github.com/user
  GF_AUTH_GITHUB_ALLOWED_ORGANIZATIONS: YOUR_GITHUB_ALLOWED_ORGANIZATIONS
```

Modify the values of Github Auth configuration from

```ini
[auth.github]
enabled = true
client_id = YOUR_GITHUB_APP_CLIENT_ID
...
```

to look like following:

```yaml
GF_AUTH_GITHUB_ENABLED: "true"
GF_AUTH_GITHUB_CLIENT_ID: YOUR_GITHUB_APP_CLIENT_ID
```

The section name `[auth.github]` should be prepended with `GF_` and the name should be capitalised and `.` be replaced with `_`.

Once ready deploy the Kubernetes secret config in the same namespace(here we are deploying in `monitoring` namespace) as Prometheus Operator using `kubectl`.

#### Step 4

Goto https://grafana.mydomain.net and now you will a special button **Sign in with GitHub**, use that to sign in with Github.

## What's next?

- Other auth providers for Grafana: https://grafana.com/docs/grafana/latest/auth/overview/#user-authentication-overview

# node.js ms on kubertnetes

## ⏳ Requirements

- [`docker`](https://docs.docker.com/get-docker/)
- [`k3d >= v5.0.3`](https://k3d.io/#installation)
- [`Helm 3`](https://helm.sh/docs/intro/install/)

Optional - yet recommanded:

- [`kubectx + kubens`](https://github.com/ahmetb/kubectx) callable via the `kubens` binary
- [`Kustomize`](https://kubernetes-sigs.github.io/kustomize/installation/)
- [`chromium`](https://www.chromium.org/Home) callable via the `chromium` binary


## 🥅 Todays Goal's

Deploy a microservice architecture app

- redis
- api      (./src/api)
- consumer (./src/pinger)
- client   (./src/poller)

### Background on ping app

1. Use `redis` to store pings, using `redis:latest@sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe` to ensure these LAB's function as expected altough `latest` should work ;)
1. To disable redis authentication Use `nodejs-ping` with tag `no-auth` or `latest@sha256:85d7474aabdd2d01802a9957c770ec157a478db71b7ce5f8d07d1e221cc39cba` see the `docker-compose-no-auth.yml`
1. Pinger & Poller are just 2 clients using `latest` tag should suffice.

In order to test you have everything `docker-compose build` will buid all images locally,
A functional a `docker-compose up` should build/pull the required images.

---

1️⃣ prep

## 🧹 Remmove/cleanup existing k3d clusters 

```sh
k3d cluster delete nodejs-demo
```

## Create k3d cluster named `nodejs-demo`

```sh
k3d cluster create nodejs-demo 
```

## Validate cluster is runnning 

```sh
kubectl cluster-info
```

Should yield somthing like the following:

```sh
Kubernetes control plane is running at https://0.0.0.0:52951
CoreDNS is running at https://0.0.0.0:52951/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:52951/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

---

🆙 next deploy - [redis](./doc/02-redis.md)
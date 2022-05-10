4️⃣.4 Microservices - `IntContainers`

### Why do we need init containers (don't we have a control loop ?)

A Pod can have multiple containers running apps within it, but it can also have one or more init containers, which are run before the app containers are started.

Init containers are exactly like regular containers, except:

`Init containers` **always run to completion**.

Each init container must **complete successfully before the next one starts** (the order count's ...)

If a Pod's init container fails, the kubelet repeatedly restarts that init container until it succeeds. However, if the Pod has a restartPolicy of Never, and an init container fails during startup of that Pod, Kubernetes treats the overall Pod as failed.

To specify an init container for a Pod, add the `initContainers` field into the Pod specification, as an array of container items (similar to the app containers field and its contents). See Container in the API reference for more details.

The status of the init containers is returned in .status.initContainerStatuses field as an array of the container statuses (similar to the .status.containerStatuses field).

## Use Case

💡 `Pinger` and `Poller` - `wait for` api before starting ping / poll ...

e.g.

  until `dig api.my-namespace.svc.cluster.local` don't continue (keep sleeping for 2 sec then try again ...)

  ```yaml
  initContainers:
      - name: init-pinger
        image: registry.gitlab.com/tikal-external/academy-public/images/bind-tools
        command: ['sh', '-c', "until dig +short A api.\${MY_POD_NAMESPACE}.svc.cluster.local; do echo waiting for api; sleep 2; done"]
  ```

  we can also map por attributes as environment variables like so:

  ```yaml
    env:
    - name: MY_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
  ```

  This is how we use `${MY_POD_NAMESPACE}` with the dig command do synamically get the namespace ...
  
## Create `initContainers` kustomization

```sh
mkdir -p deployment/kustomize/initContainers/{pinger,poller}
```

## 4️⃣.4.1 Let's apply to pinger & poller

Considering we are using kustomize we can path our existing pinger/poller like the following:

### Create deployment/kustomize/initContainers/pinger/deployment.yaml

dig - get the ip of a given dns name, in our case  `api.my-namespace.svc.cluster.local` so pinger / poller's main container will not start before the api is ready for connections

```yaml
cat<<EOF>>deployment/kustomize/initContainers/pinger/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pinger
spec:
  template:
    spec:
      initContainers:
      - name: init-pinger
        image: registry.gitlab.com/tikal-external/academy-public/images/bind-tools
        command: ['sh', '-c', "until dig +short A api.\${MY_POD_NAMESPACE}.svc.cluster.local && echo continuing ...; do echo waiting for api; sleep 2; done"]
        env:
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF
```

### 4️⃣.4.2 create deployment/kustomize/initContainers/poller/deployment.yaml

```yaml
cat<<EOF>>deployment/kustomize/initContainers/poller/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: poller
spec:
  template:
    spec:
      initContainers:
      - name: init-poller
        image: registry.gitlab.com/tikal-external/academy-public/images/bind-tools
        command: ['sh', '-c', "until dig +short A api.\${MY_POD_NAMESPACE}.svc.cluster.local && echo continuing ...; do echo waiting for api; sleep 2; done"]
        env:
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF
```

### 4️⃣.4.3 🧪 Let's `kustomize` it!

```yaml
cat<<EOF>>deployment/kustomize/initContainers/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # do what we did in configs + this !
  - ../configs/

patchesStrategicMerge:
  - ./pinger/deployment.yaml
  - ./poller/deployment.yaml
EOF
```

### 4️⃣.4.3 🧪 Let's test  it !

```sh
kubectl apply -k ./deployment/kustomize/initContainers
```

Should yield:

```sh
namespace/my-namespace created
configmap/api-config-cbgkc6gd88 created
secret/redis-secret created
service/api created
service/redis created
persistentvolumeclaim/redis-data created
deployment.apps/api created
deployment.apps/pinger created
deployment.apps/poller created
deployment.apps/redis created
ingress.networking.k8s.io/nginx created

```

A quick kubectl get po will now show somthig like th folowing:
Noth the highlighted `Init:0/1` in both pinger & poller pods ...


```sh
NAME                      READY   STATUS              RESTARTS   AGE
pinger-7b584cb849-s5t2r   0/1     `Init:0/1`            0          11s
poller-5c47ff6979-22zgs   0/1     `Init:0/1`            0          11s
redis-675d5f8fc5-n4g5l    0/1     ContainerCreating   0          11s
api-7b8ff8b48c-bjq6v      1/1     Running             0          11s

```

```sh
kubectl logs poller-5c47ff6979-22zgs init-poller
```

yields:

```sh
10.43.196.235
continuing ...
```

`kubectl get svc` yields: `api     ClusterIP   10.43.196.235   <none>        8080/TCP   5m23s` which is the `api.${MY_POD_NAMESPACE}.svc.cluster.local` rsoulvable address ... which is what out pinger / poller need in order to start !


---

🆙 next - [HELM](05-00-helm.md) 


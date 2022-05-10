# 4️⃣ Apply with kustomize
 
[kustomize](kustomize.io) is a tool used to customize kuberentes manifests.
An in depth intro is available [here](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/).

In our example we will use a `kustomization.yaml` file to act like our "main" which will just tell the kubectl command to template the yaml files under `./deployment/kustomize/manifests/...` and apply them to the current kubernetes context.

```yaml
cat<<EOF>>./deployment/kustomize/manifests/kustomization.yaml
resources:
 - ns.yaml
 - ./api/deployment.yaml
 - ./api/svc.yaml
 - ./pinger/deployment.yaml
 - ./poller/deployment.yaml
 - ./redis/deployment.yaml
 - ./redis/svc.yaml

namespace: my-namespace
```

note that:
(1) `ns.yaml` is in the `./deployment/kustomize/manifests/` dir, + all the resources in `./api`, `./pinger`, `./poller` and `./redis` do not specify the namespace field.
(2) kustomize an do much more ... it is important to know in addition to helm which we will cover later on.

## 4️⃣.1️⃣ Using kubectl 

```sh
kubectl apply --kustomize ./deployment/kustomize/manifests/
```

Should yield:

```sh
namespace/my-namespace created
service/api created
service/redis created
deployment.apps/api created
deployment.apps/pinger created
deployment.apps/poller created
deployment.apps/redis created
```

## 4️⃣.2️⃣ Validating deployments/po/svc

Using kubectl `get` deploy,pod,svc `-n my-namespace` in the my-namespace namespace.


```sh
kubectl get deploy,pod,svc -n my-namespace
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/poller   1/1     1            1           3m49s
deployment.apps/redis    1/1     1            1           3m49s
deployment.apps/api      1/1     1            1           3m49s
deployment.apps/pinger   1/1     1            1           3m49s

NAME                          READY   STATUS    RESTARTS   AGE
pod/poller-5d99499d94-8crq9   1/1     Running   0          3m49s
pod/redis-7dcd746c6-rt2mw     1/1     Running   0          3m49s
pod/api-6cf97d64f6-vznzc      1/1     Running   0          3m49s
pod/pinger-8bb57b4bf-kd5f4    1/1     Running   0          2m29s

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/api     ClusterIP   10.43.93.224   <none>        8080/TCP   3m50s
service/redis   ClusterIP   10.43.82.158   <none>        6379/TCP   3m49s
```

---
🆙 next - [Add an Ingress resource](04-01-ingress.md)

## 5️⃣ Install redis chart 📉 

Similar to the image we used previously `bitnami/redis` from [bitnami](https://charts.bitnami.com/bitnami)

### 5️⃣1.1 Register the repository 

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### 5️⃣.2 Install redis with some specific values:

In order to test our first node version with redis with no authentication we will install redis with the following values:

```sh
helm install redis \
  --set image.tag='5.0' \
  --set cluster.enabled=false \
  --set usePassword=false \
  --version 12.7.4 \
  bitnami/redis
```

Should yield:

Please note these are part of the `bitnami/redis/templates/NOTES.txt` it has valuable info on the release:

```sh
NAME: redis
LAST DEPLOYED: Wed Nov 17 22:30:31 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **
Redis(TM) can be accessed via port 6379 on the following DNS name from within your cluster:

redis-master.default.svc.cluster.local



To connect to your Redis(TM) server:

1. Run a Redis(TM) pod that you can use as a client:
   kubectl run --namespace default redis-client --rm --tty -i --restart='Never' \
   --image docker.io/bitnami/redis:5.0 -- bash

2. Connect using the Redis(TM) CLI:
   redis-cli -h redis-master

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/redis-master 6379:6379 &
    redis-cli -h 127.0.0.1 -p 6379


WARNING: Rolling tag detected (bitnami/redis:5.0), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://docs.bitnami.com/containers/how-to/understand-rolling-tags-containers/
```

### 5️⃣.3 Test redis

```sh
kubectl exec -it `kubectl get po -l app=redis | grep redis| awk '{print $1}'`  redis-cli get pings
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
```
- Depending on your setup ... Shoukd yield:

```sh
"7"
```

### 5️⃣.4 Export values 

In our next lab we will be using the `bitnami/redis` chart as a depdencey, beofre we `uninstall` the chart let's get the values we used earlier like so:

```sh
helm get values redis
USER-SUPPLIED VALUES:
cluster:
  enabled: false
image:
  tag: "5.0"
usePassword: false
```

Let's remember this for our next lab

### 5️⃣.5 Export cleanup for next 🥼 LAB

```sh
helm uninstall redis
```


---

🆙 next - [Build Ping App Charts](05-03-ping-chart.md) 
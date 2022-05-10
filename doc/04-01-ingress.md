# 4️⃣ Microservices - Ingress traffic

> ![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/ing.svg)
![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/svc.svg)


Some background on Ingress:

Ingress is an `API object` that manages `external access` to the services in a cluster, typically HTTP.

![](https://kroki.io/mermaid/svg/eNqNkT1PwzAQhvf-ipOygBRXIXwIOSgTCxIDgjHK4I9zatXYkZ0AQ388SWyaVixdfPbr9x7fnTvP-h28vlcbAGE02uGqibG9Jlt4sZ3HEMgns6xDCU_c12Ack8CZYVaghy2pdXQ1yd3OsKQRUh-8G4fpCH40eAjov7TA5iPGxRtG3i11CDOGAf2avtxG50Tqnbxp3pxs_8nlUUYrl1ZYCM-ooDdMW1DaGJpJKfMweLdHmiml0p58azns6F3_kwtnnKdZURTVKWP_GBLhtnwQeH8RZLo7g6TWEmjNpBnn_JxSrpT44BH0N5Y8NZ_PE5mXci5ytcUfjM2fqrGEFKvNL14uraI=)

Ingress may provide `load balancing`, `SSL termination` and `name-based virtual hosting`.

## Use k3d(s) to setup a cluster for us + loadBalancer listening on 80 & 443

```sh
k3d cluster create devcluster \
--api-port 127.0.0.1:6443 \
-p 80:80@loadbalancer \
-p 443:443@loadbalancer
```

This command should yield:

```sh
INFO[0000] portmapping '80:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] portmapping '443:443' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-devcluster'             
INFO[0000] Created volume 'k3d-devcluster-images'       
INFO[0000] Starting new tools node...                   
INFO[0000] Starting Node 'k3d-devcluster-tools'         
INFO[0001] Creating node 'k3d-devcluster-server-0'      
INFO[0001] Creating LoadBalancer 'k3d-devcluster-serverlb' 
INFO[0001] Using the k3d-tools node to gather environment information 
WARN[0002] failed to resolve 'host.docker.internal' from inside the k3d-tools node: Failed to read address for 'host.docker.internal' from command output 
INFO[0002] HostIP: using network gateway...             
INFO[0002] Starting cluster 'devcluster'                
INFO[0002] Starting servers...                          
INFO[0002] Starting Node 'k3d-devcluster-server-0'      
INFO[0002] Deleted k3d-devcluster-tools                 
INFO[0008] Starting agents...                           
INFO[0008] Starting helpers...                          
INFO[0008] Starting Node 'k3d-devcluster-serverlb'      
INFO[0014] Injecting '192.168.32.1 host.k3d.internal' into /etc/hosts of all nodes... 
INFO[0014] Injecting records for host.k3d.internal and for 2 network members into CoreDNS configmap... 
INFO[0015] Cluster 'devcluster' created successfully!   
INFO[0015] You can now use it like this:                
kubectl cluster-info
```

## Getting into Context

I recommend using `kubectx` / `kubens` for these tasks, to make sure your on the right cluster you can do the following:

```sh
k3d kubeconfig get devcluster > $HOME/.k3d/kubeconfig
export KUBECONFIG=$HOME/.k3d/kubeconfig
```

- Apply ping api from previous lab

Setup the ping-pong app we created in previous labs.

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

#### 4️⃣.1️⃣ 🚀 Ingress (finally!)

- An ingress as wev'e red earlier will map between a `hostname` or `*` (all hosts) pointing to a service in our case the `api` service:

- So, Our ingress object will look like the following:

```sh
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
        # the backend of this ingress
      - backend:
          service:
            # the name of the service representing the backend
            name: api
            port:
              number: 8080
              # smarter ;)
              # name: http
        path: /
        pathType: Prefix
```

#### 4️⃣.2️⃣ Let's Kustomize this !

Create a diretory for out kustomization files

```sh
mkdir ./deployment/kustomize/ingress
```

- Create a kustomization file, pointing to `../depoyment/manifests` as our `base-config` + adding `ingress.yaml` to it.
> Considering our kustomization is in the namespace `my-namespace` we will have to keep that also for the ingress resoure.

```sh
cat<<EOF>>./deployment/kustomize/ingress/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
 - ../manifests
 - ingress.yaml

namespace: my-namespace
```

- Create the resoure itself:

```sh
cat<<EOF>>./deployment/kustomize/ingress/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
        # the backend of this ingress
      - backend:
          service:
            # the name of the service representing the backend
            name: api
            port:
              number: 8080
              # smarter ;)
              # name: http
        path: /
        pathType: Prefix
EOF
```

#### 4️⃣.3️⃣ Apply the ingress:

```sh
kubectl apply -k ./deployment/kustomize/ingress/ 
```

Should yield:

```sh
namespace/my-namespace unchanged
service/api configured
service/redis configured
deployment.apps/api unchanged
deployment.apps/pinger configured
deployment.apps/poller configured
deployment.apps/redis configured
ingress.networking.k8s.io/nginx configured
```

#### 4️⃣.4️⃣ Test it ~

🧪 Plan:

1. Stop our pinger
2. Query for pings
3. Ping
4. Query again

Considering we have port 80 & 443 pointing at our `@loadbalancer` whih points to the ingress-controller inside our cluster we can easily access `http://localhost/` to get ping count ;), or `http://localhost/pinger` to ping it.


1. Stop pinger (so we don't get more pings ...)

  ```sh
  # see what were scaling down:
  kubectl get pod -l app=pinger -n my-namespcae

  # NAME                     READY   STATUS    RESTARTS   AGE
  # pinger-8bb57b4bf-nwx54   1/1     Running   0          29s
  kubectl scale deploy pinger --replicas=0 -n my-namespace

  # kubectl get pod -l app=pinger -n my-namespcae 
  # would yield:
  # kgp -l app=pinger
  # NAME                     READY   STATUS        RESTARTS   AGE
  # pinger-8bb57b4bf-nwx54   1/1     Terminating   0          95s

  ```

2. get pings:

  ```sh
  curl localhost
  Current ping count: null
  ```

3. ping:

  ```
  curl -X POST localhost/ping
  *   Trying ::1...
  * TCP_NODELAY set
  * Connected to localhost (::1) port 80 (#0)
  > POST /ping HTTP/1.1
  > Host: localhost
  > User-Agent: curl/7.64.1
  > Accept: */*
  > 
  < HTTP/1.1 204 No Content
  < Access-Control-Allow-Origin: *
  < Date: Fri, 12 Nov 2021 13:06:48 GMT
  < Etag: W/"a-bAsFyilMr4Ra1hIU5PyoyFRunpI"
  < X-Powered-By: Express
  < 
  * Connection #0 to host localhost left intact
  * Closing connection 0
  ```

4. get pings again:

  ```sh
  curl localhost
  Current ping count: 3
  ```

---
🆙 next - [ConfigMaps and Secrets](04-02-configs.md) 



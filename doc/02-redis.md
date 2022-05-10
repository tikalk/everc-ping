# 2️⃣ deploy redis

##  use official docker.io/librery/redis

* get image full registry name by running:

  ```yaml
  docker pull redis
  ```

* Result

  ```sh
  Using default tag: latest
  latest: Pulling from library/redis
  Digest: sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe
  Status: Image is up to date for redis:latest
  docker.io/library/redis:latest
  ```

  > 🔔 In result above image `redis`'s full name is really `docker.io/library/redis:latest` (`docker.io` - docker maintained registry, `library` officially maintained by docker team, `latest` becuse we didn't specify is default version) 
  
  > 🔔 the `latest` tag's digest sha -> `sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe` 

  > 🔔 So the exact version of the image is `docker.io/library/redis:latest:sha256@a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe`

### Generate a `deployemnt.yaml` - declerative configuration

- Create deployment for redis:
  - image name: `docker.io/library/redis:`
  - image version: `latest:sha256@a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe`

```sh
# 🔔 note: --dry-run=client -oyaml > ./deployment/kustomize/manifests/redis/deployment.yaml for reuse

kubectl create deployment --image=docker.io/library/redis:latest@sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe redis --port=6379 --dry-run=client -oyaml > ./deployment/kustomize/manifests/redis/deployment.yaml
```

## apply deployment from `./deployment/kustomize/manifests/redis/deployment.yaml`

📓 -> Any yaml file including kubernes configuration, in our example, a `deployment` object, 
can be done via `kubectl apply -f /path/to/file [ -f another-file ] ...`

```sh
kubectl apply -f ./deployment/kustomize/manifests/redis/deployment.yaml
```

## validate redis is functional:

📓 the pod id presented below, may differ in your setup ...

```sh
kubectl get po 
NAME                     READY   STATUS    RESTARTS   AGE
redis-7dcd746c6-sj9w8   1/1     Running   0          88m
```

### get pod by label:

The following command will help make this command more user-freindly using the label/selector of the deployment:

```sh
kubectl get po -l app=redis
```

### using port-froward to pod (reach a pod which is part fo the deployment object)

- This is equivalent in docker ->  docker run `without -p` (sevice not accessibel via host) ... and we must `docker attach <contaoerId>`

```sh
kubectl port-forward  redis-7dcd746c6-sj9w8 6379:6379
```

### using service to expose a deployment to other services **in the cluster**

For a service to be able to access another service in the cluster, we need a service of type `ClusterIP` which is the default kuberentes service type (more on the other later ...), once you have a service name `foo` pointing to a `deployment` by using tags + selctors:

e.g.

```yaml

# from ./deployment/kustomize/manifests/redis/deployment.yaml
...
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis
...

```

### generate the service file `../deployment/kustomize/manifests/redis/svc.yaml`

Using `kubectl expose deployment`

```sh
kubectl expose deployment redis --port=6379 --dry-run=client -oyaml > ./deployment/kustomize/manifests/redis/svc.yaml
```

## apply svc from `./deployment/kustomize/manifests/redis/svc.yaml`

```sh
kubectl apply -f ./deployment/kustomize/manifests/redis/svc.yaml
```

## using port-froward to svc (points to the deployment instance / replica)

```sh
kubectl port-forward svc/redis 6379:6379
```


## Checking connection using kubectl exec:

```sh
kubectl exec -it `kubectl  get pod -l app=redis | grep redis| awk '{print $1}'` -- redis-cli GET pings
```

should yield:

```sh
""
```

After we deploy pinger we will run this again ... 

---

🆙 next deploy - [microservices](./03-microservices.md)

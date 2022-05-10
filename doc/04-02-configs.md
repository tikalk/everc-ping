4️⃣.2 Microservices - `Volumes`, `Configmaps` and `Serets`

> ![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/pvc.svg)
![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/pv.svg)
![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/secret.svg)

Use case:

Our app needs a configuration file + secret value 
-  For the `redis` instance:
    - A persistent volume for our `redis` data (so data persists between restatarts) mapped to `/data/`
    - A password in form of a kubernetes `secret` named `REDIS_PASSWORD`
    - A configuration change to run with auth enabled
-  For the `api` instance:
    - `secret` with redis-password as Environment variable named `REDIS_PASS`
    - `configmap` Configuration file with redis host + port

Background:

- In out api's `config.js` the `NODE_ENV` determins the configuration file to load 
  ```js
  // Load environment dependent configuration
  var env = config.get('env');
  config.loadFile('./config/' + env + '.json');
  ```
- Applicaion root is `/opt/tikal/` we would like to mount our config map to `/opt/tikal/config/` with the `data` stored in the `api-configmap` with the name `kubernetes.json`

---

In this lab 🥼 We will:
1. Create a secret for our `redis`  
1. Add a persistent volume claim for `redis`

Once completed:
1. Create a configmap incluging our example `kuberentes.json`
1. Test out our new new configration

### 4️⃣.2.1 Create a directory for our kustomizations

```sh
mkdir -p ./deployment/kustomize/configs/{api,redis}
```

### ❗ About "Secrets"

TLDR; **there are a 64bit encoding so there not secure by default ...**

A Secret is an object that contains a small amount of sensitive data such as a password, a token, or a key. Such information might otherwise be put in a Pod specification or in a container image. Using a Secret means that you don't need to include confidential data in your application code.

Because Secrets can be created independently of the Pods that use them, there is less risk of the Secret (and its data) being exposed during the workflow of creating, viewing, and editing Pods. Kubernetes, and applications that run in your cluster, can also take additional precautions with Secrets, such as avoiding writing confidential data to nonvolatile storage.

Secrets are similar to ConfigMaps but are specifically intended to hold `confidential data`.

## 4️⃣.2.2 Create Secret named `redis-secret`

There are a few types of secrets (e.g certificate / key-pairs, docker-credentials template), in most usecases a `generic` secret is used to store key/value pairs which can be mapped to a deployment.

```sh
kubectl create secret generic redis-secret --from-literal=REDIS_PASSWORD=MyS3cr3t -oyaml --dry-run=client > ./deployment/kustomize/configs/redis/secret.yaml
```

- Will yield:

```sh
apiVersion: v1
data:
  REDIS_PASSWORD: TXlTM2NyM3Q=
kind: Secret
metadata:
  creationTimestamp: null
  name: redis-secret
```

> As already noted in many cases we will use some kind of Secret Management System such as `Vault`, `AWS/GCP/AZR secresManager` 

- Let's Check our secret

```sh
echo -e TXlTM2NyM3Q= | base64 -d; echo
```

- Will yield `MyS3cr3t` (🔓!) ...

### 🆙 Update our deployment to use the values in the `secret` as environment variables:

In our previous labs we created a deployment.yaml for redis `./deployment/kustomize/manifests/redis/deployment.yaml` this file will now be patched with:

- `envFrom` the `redis-secret` secret

```yaml
...
        name: redis
        envFrom:
          - secretRef:
              name: redis-secret
```

In addition in order to be secure ... we will need some kind of setup secript which will insert the `$REDIS_PASSWORD` to the redis.conf ...

A non secure way to do so would be to create a configuration file named `redis.conf` with the line `--requirepass MyS3cr3t` 👎❗

Lucikly `bitnami/redis` has that functionality built-in !

See -> https://hub.docker.com/r/bitnami/redis/ if we set at environment variable named `REDIS_PASSWORD` bitnami does the trick for us 👏👏

The Final `deployment.yaml` will look like the following - **don't do it just yet we have another step first ...**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis
  name: redis
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
    spec:
      containers:
      - image: bitnami/redis
        # image: registry.gitlab.com/tikal-external/academy-public/images/bitnami-redis
        name: redis
        envFrom:
          - secretRef:
              name: redis-secret
        ## 
        ports:
        - containerPort: 6379
        resources: {}
```

- Feel free to edit your existing `deployment/kustomize/manifests/redis/deployment.yaml` with these changes ... it will work with a password, which is great. ❗ But, what we'll be missing is a `persistence volume` to keep our "pings safe" between restarts ... 😉

### 4️⃣.2.3 - Add a persitence volume

A `PersistentVolume (PV)` is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI, or a cloud-provider-specific storage system.

A `PersistentVolumeClaim (PVC)` is a request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany, see AccessModes).

With `k3d` we have a `local-storage` provisoiner enabled by default ...
If we do not specify the `storageClass` the `default` will be used.

- check your available storage classes (or no provisioning will occur ...)

```sh
kubectl get storageclass

NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  8h
```

- Provision a 100 MB volume:
   
  note the `storage: 100Mi`

```yaml
cat<<EOF>>./deployment/kustomize/configs/redis/pvc.yaml
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    labels:
      run: redis
    name: redis-data
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 100Mi
EOF
```

### Mount our `Volume` to the `Pod` via `Deployment` spec

* `volumeMounts`: represent the mount path name and mode of the volume (similar to confimap mounts)
* `name`: name of the `persistent-volume-claim` (we created prviously)

```yaml
        volumeMounts:
          - mountPath: /data
            name: redis-data
        resources: {}
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-data
```

- Final `Deployment` should now look like the following:

```yaml
cat<<EOF>./deployment/kustomize/configs/redis/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis
  name: redis
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
    spec:
      containers:
      - image: bitnami/redis
        # image: registry.gitlab.com/tikal-external/academy-public/images/bitnami-redis
        name: redis
        envFrom:
          - secretRef:
              name: redis-secret
        # Alternate (more granular option)
        # env:
        # - name: REDIS_PASSWORD
        #   valueFrom:
        #     secretKeyRef:
        #       name: redis-secret
        #       key: REDIS_PASSWORD
        ports:
        - containerPort: 6379
        volumeMounts:
          - mountPath: /data
            name: redis-data
          # Using ./configmam.yaml as another example
          # - mountPath: /opt/bitnami/redis/mounted-etc/redis.conf
          #   name: config
          #   subPath: redis.conf
        resources: {}
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-data
      # - name: config
      #   configMap:
      #     name: redis-config

EOF
```

At this point you should have the complete redis kustomization.

### 4️⃣.2.4 Let's `kustomize` it!

```sh
cat<<EOF>deployment/kustomize/configs/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # do what we did with the ingress lab
  - ../ingress
  - ./redis/pvc.yaml
  - ./redis/secret.yaml

  # Patch the ./manifests/redis/deployment.yaml deployment with ./redis/deployment.yaml

patchesStrategicMerge:
  - ./redis/deployment.yaml

namespace: my-namespace

EOF
```


### 4️⃣.2.5 🧪 Let's test  it !

```sh
kubectl apply -k ./deployment/kustomize/configs
```

- using `redis-cli` check the status of redis - does it require auth ?
  
```sh
kubectl -n my-namespace exec -it `kubectl -n my-namespace get pod -l app=redis | grep redis | awk '{print $1}'` -- redis-cli -a MyS3cr3t GET pings
```

**should yield:** 

```sh
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
(nil)
```

- Is our `api` functioning ? (`kubectl get po`)
- What's missing ?
- Propose a fix ...

---

🆙 next - [ConfigMaps and Secrets](04-03-configmap.md) 


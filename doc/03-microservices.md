3️⃣ Microservices deployment(s)

### Generate Deployment + Service for `api` and `pinger` & `poller  Microservices

- nodejs-ping - our api server
- pinger - **pings** the api sever every `n` secods 
- poller - **polls** the api sever `n` secods 


#### 3️⃣.1️⃣ The following yaml represents the `api` deployment

Image used: `registry.gitlab.com/tikal-external/academy-public/images/nodejs-ping`

- Generate manifest with --dry-run:

```sh
kubectl create deployment api --image=registry.gitlab.com/tikal-external/academy-public/images/nodejs-ping --dry-run=client -oyaml > ./deployment/kustomize/manifests/api/deployment.yaml
```

- Add resource requests + limits

> 📓 the below `resources` tag can limit the requested cpu / ram provided by the hosting machine to the pod

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: api
  name: api
  ...
    spec:
      containers:
      - image: registry.gitlab.com/tikal-external/academy-public/images/nodejs-ping:latest
        name: nodejs-ping
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### 3️⃣.2️⃣ The following yaml represents the `poller` deployment

Image used: `registry.gitlab.com/tikal-external/academy-public/images/poller:latest`

- Generate manifest with --dry-run:

```sh
kubectl create deployment poller --image=registry.gitlab.com/tikal-external/academy-public/images/poller --dry-run=client -oyaml > ./deployment/kustomize/manifests/poller/deployment.yaml
```

- Customize the command + args:

#### 3️⃣.3️⃣ The following yaml represents the `pinger` deployment

> 🔔 The following command was used to generate the initial deployment:

Image used: `registry.gitlab.com/tikal-external/academy-public/images/pinger:latest`

`kubectl create deployment pinger --image=registry.gitlab.com/tikal-external/academy-public/images/pinger:latest --dry-run=client -oyaml > deployment/kustomize/manifests/pinger/deployment.yaml`

See below we've added an environment variable specify `command` + the 1st command-line arg 

```yaml
...
    spec:
      containers:
      - image: registry.gitlab.com/tikal-external/academy-public/images/pinger:latest
        name: pinger
        command:
          - pinger.sh
        args:
          # first argument to punger.sh
          - "3"
```

- The full yaml:

```yaml
# created by running:

# to create pinger => copy and past the following lines 
cat <<EOF>> ./deployment/kustomize/manifests/pinger/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: pinger
  name: pinger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pinger
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: pinger
    spec:
      containers:
      - image: registry.gitlab.com/tikal-external/academy-public/images/pinger:latest
        name: pinger
        command:
          - pinger.sh
        args:
          # first argument to punger.sh
          - "3"
        resources: {}
status: {}


EOF
```

The following yaml represents the `api` svc

```sh
# copy and past the following lines to get 
# plesae not the name is `api` 

cat <<EOF>> ./deployment/kustomize/manifests/api/svc.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: api
  name: api
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: api
status:
  loadBalancer: {}
EOF
```

---
🆙 next - [Managing Apps with kustomize](04-00-kustomization.md) 

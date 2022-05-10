4️⃣.2 Microservices - `Volumes`, `Configmaps` and `Serets`

![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/cm.svg)
![](https://raw.githubusercontent.com/kubernetes/community/1ef48631b89141e8b614002b4bdce6560df31958/icons/svg/resources/labeled/secret.svg)

Use case:

Our app needs a configuration file + secret value 
-  For the `api` instance:
    - `secret` with redis-password as Environment variable named `REDIS_SERVICE_PASSWORD` (see `./src/api/config/config.js` for the api's defaul values )
    - `configmap` Configuration file with redis host + port defined in a configmap ...

Background:

- In out api's `config.js` the `NODE_ENV` determins the configuration file to load 
  ```js
  // Load environment dependent configuration
  var env = config.get('env');
  config.loadFile('./config/' + env + '.json');
  ```
- Applicaion root is `/opt/tikal/` we would like to mount our config map to `/opt/tikal/config/` with the `data` stored in the `api-config` with the name `kubernetes.json`

---

In this lab 🥼 We will:
1. Create a secret for our `api` + add a persistent volume claim
1. Create a configmap incluging our example `kuberentes.json`
1. Test our new new configration

### 4️⃣.3.1 Create a configmap

It could look like the following configmap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  kubernetes.json: |
    {
      "redis_host": "redis",
      "redis_port": 6379
    }
```

And then we need to map that Configmap's data `kuberentes.json` to `/opt/tikal/config` path on the container.

Simlar to how we mounted a volume we mount a configmap which is also a volume containing a file ...

It looks exactly like the following **so let's do this first**:

```yaml
cat<<EOF>./deployment/kustomize/configs/api/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: api
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - image: registry.gitlab.com/tikal-external/academy-public/images/nodejs-ping:latest
        name: nodejs-ping
        env:
          - name: NODE_ENV
            # the name of our configfile ... without .json
            value: kubernetes
            # see ./src/api/config/config.js for the api's defaul values
          - name: REDIS_SERVICE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: redis-secret
                key: REDIS_PASSWORD
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        volumeMounts:
            # where exactly to mount the volume
            # when not using subPath omit the file name jsut pass /opt/tikal/config
          - mountPath: /opt/tikal/config/kubernetes.json
            name: config
            # optional - necesary in this case considering it overrides an existing file with that name already ...
            subPath: kubernetes.json
        resources: {}
      volumes:
      - name: config
        configMap:
          name: api-config
status: {}
EOF
```

Instead of manyally creating the config map we can do somthing more simple with `kustomize`:

- create a config file:

```sh
cat<<EOF>./deployment/kustomize/configs/kubernetes.json
{
  "redis_host": "redis",
  "redis_port": 6379
}
EOF
```

- Add to our existing configs kustomizstion the following:

```yaml
...
configMapGenerator:
- name: api-config
  files:
    - kubernetes.json
```

### 4️⃣.3.2 🧪 Let's `kustomize` it!

Our kustomization will be the following:

```yaml
cat<<EOF>./deployment/kustomize/configs/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../ingress
  - ./redis/pvc.yaml
  - ./redis/secret.yaml

patchesStrategicMerge:
  - ./redis/deployment.yaml
  - ./api/deployment.yaml

configMapGenerator:
- name: api-config
  files:
    - kubernetes.json

namespace: my-namespace
EOF
```

Let's apply it now like we did in our previous lab

```sh
kubectl apply -k ./deployment/kustomize/configs

```

### 4️⃣.3.3 🧪 Let's test  it !

- Review the api log (kubectl get po -l app=api)

```sh
kubectl logs -l app=api

> msa-api@1.0.0 start /opt/tikal
> node api.js

loading ./config/kubernetes.json
Sun, 14 Nov 2021 20:07:11 GMT body-parser deprecated bodyParser: use individual json/urlencoded middlewares at api.js:41:9
Sun, 14 Nov 2021 20:07:11 GMT body-parser deprecated undefined extended: provide extended option at node_modules/body-parser/index.js:105:29
Connecting to cache_host: redis://10.43.40.109:6379
Server running on port 8080!
```

> Note `loading ./config/kubernetes.json` 


Let's see that we have config map and it's mapping to the pod

Running `kubectl describe po -l app=api` will yield:

```yaml
...
    Environment:
      NODE_ENV:                kubernetes
      REDIS_SERVICE_PASSWORD:  <set to the key 'REDIS_PASSWORD' in secret 'redis-secret'>  Optional: false
    Mounts:
      /opt/tikal/config/kubernetes.json from config (rw,path="kubernetes.json")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bvtcd (ro)
      ...
```

## Conclution

Deploying to Kubernets is a lot of yaml !
`Kustomize` is one way to deal with it `Helm` is another we will cover in the next labs.

---

🆙 next - [HELM](05-00-helm.md) 


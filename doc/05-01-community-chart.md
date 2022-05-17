# 5️⃣ 📉 Work with existing charts [whoami]

In order to review the structure of a chart will take an example stable chart `whoami` - chosen due to it's components.

## ⌛ Perquisites

- `helm 3` [installation](https://helm.sh/docs/intro/install/)

### 5️⃣.1 Get the chart locally & examine it

Add a helm repo to your local helm repo list

```sh
helm repo add cowboysysop https://cowboysysop.github.io/charts/
```

Once we add a helm repo we can search for example:

```sh
helm search repo whoami
```

Should yield:

```sh
NAME                    CHART VERSION   APP VERSION     DESCRIPTION                                       
cowboysysop/whoami      2.5.1           1.5.0           Tiny Go webserver that prints os information an...
```

Let's download version `2.5.0` which is latest -1, just for this example (ommiting the --version will obviously get the latest version of the chart)

Please execute 
```sh
helm pull --untar --version=2.5.0 cowboysysop/whoami
```` 
Which will download a tar file including the helm chart to a directory named `./whoami`

- We get the following:

```sh
./whoami
├── Chart.lock               - depdency lock file.
├── Chart.yaml               - the Chart manifest file - `app version` and `chart version`
├── charts                   - a folder for dependencies (Other charts / library charts.
│   └── common
├── ci
│   └── test-values.yaml     - test values (for helm tests)
├── templates
│   ├── NOTES.txt            - helm installation info notes (which are templates too)
│   ├── _helpers.tpl         - helm templating functions 
│   ├── deployment.yaml      - a template for `deployment`
│   ├── ingress.yaml         - a template for `ingress`
│   ├── pdb.yaml             - a template for `pod distrubtion budget` 
│   ├── service.yaml         - a template for kubernetes `service` 
│   ├── serviceaccount.yaml  - a template for kubernetes `service account` 
│   └── tests - folder for tests!
└── values.yaml - The default values (if no other is provided/overrides this one is used)
```

### 5️⃣.2 Learn what this chart would do by default:

```sh
helm template my-whoami ./whoami 
```
(Similar to running kustomize build ./path/to/kustomization.)

Should yield:

```yaml
---
# Source: whoami/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-whoami
  labels:
    helm.sh/chart: whoami-2.5.1
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
    app.kubernetes.io/version: "1.5.0"
    app.kubernetes.io/managed-by: Helm
---
# Source: whoami/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-whoami
  labels:
    helm.sh/chart: whoami-2.5.1
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
    app.kubernetes.io/version: "1.5.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
---
# Source: whoami/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-whoami
  labels:
    helm.sh/chart: whoami-2.5.1
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
    app.kubernetes.io/version: "1.5.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: whoami
      app.kubernetes.io/instance: my-whoami
  template:
    metadata:
      labels:
        app.kubernetes.io/name: whoami
        app.kubernetes.io/instance: my-whoami
    spec:
      serviceAccountName: my-whoami
      securityContext:
        {}
      containers:
        - name: whoami
          securityContext:
            {}
          image: "containous/whoami:v1.5.0"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            timeoutSeconds: 1
            failureThreshold: 3
            successThreshold: 1
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            timeoutSeconds: 1
            failureThreshold: 3
            successThreshold: 1
          resources:
            {}
---
# Source: whoami/templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "my-whoami-test-connection"
  labels:
    helm.sh/chart: whoami-2.5.1
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
    app.kubernetes.io/version: "1.5.0"
    app.kubernetes.io/managed-by: Helm
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['my-whoami:80']
  restartPolicy: Never
```

### 5️⃣.3 Learn what this chart could potentially do by examining the `values.yaml` file

See the full `./whoami/values.yaml` I will just highlight 2 sections we wish to override:

```yaml
ingress:
  enabled: false

  # IngressClass that will be be used to implement the Ingress
  ingressClassName: ""

  # Ingress path type
  pathType: ImplementationSpecific

  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: whoami.local
      paths: []
  tls: []
  #  - secretName: whoami-tls
  #    hosts:
  #      - whoami.local

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi
```

❗ Similar to the overrides we did with kustomize previously, 
   With Helm the repetative tasks of `service`, `ingress`, `resource-limits` are alredy generic enough so a every chart has these "premitives" out of the box.


##### 5️⃣.4 Override default values via cli with `--set`:

If we were to say `--set resources.limits.cpu=100m` `--set resources.limits.memory=128Mi` `--set resources.requests.cpu=50m` `--set resources.requests.memory=64Mi`

```sh
helm template --set resources.limits.cpu=100m --set resources.limits.memory=128Mi --set resources.requests.cpu=50m --set resources.requests.memory=64Mi my-whoami ./whoami/templates/deployment.yaml
```

So our `deployment.yaml` now looks like:

```yaml
---
# Source: whoami/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-whoami
  labels:
    helm.sh/chart: whoami-2.5.1
    app.kubernetes.io/name: whoami
    app.kubernetes.io/instance: my-whoami
    app.kubernetes.io/version: "1.5.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: whoami
      app.kubernetes.io/instance: my-whoami
  template:
    metadata:
      labels:
        app.kubernetes.io/name: whoami
        app.kubernetes.io/instance: my-whoami
    spec:
      serviceAccountName: my-whoami
      securityContext:
        {}
      containers:
        - name: whoami
          securityContext:
            {}
          image: "containous/whoami:v1.5.0"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            timeoutSeconds: 1
            failureThreshold: 3
            successThreshold: 1
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            timeoutSeconds: 1
            failureThreshold: 3
            successThreshold: 1
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 50m
              memory: 64Mi
```

##### 5️⃣.5 Use your own `values.yml` file:

You could use your own custom `values.yaml` file (and keep it in source control ❗❗❗) and run helm like so:

```sh
mkdir -p ./deployment/helm/values/whoami/
# you can save a full copy as s reference ...
# cp ./whoami/values.yaml ./deployment/helm/values/whoami/values.yaml
```

```yaml
cat<<EOF>./deployment/helm/values/whoami/my-whoami.yaml
ingress:
  enabled: true
  hosts:
    - paths: 
        - /

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF
```

> This `values override file` is equivallent to the command we ran previosuly:
> ```sh
> helm template --set resources.limits.cpu=100m --set resources.limits.memory=128Mi --set > resources.requests.cpu=50m --set resources.requests.memory=64Mi my-whoami ./whoami/templates/deployment.yaml
> ``` 

### 5️⃣.6 🚀 Let's Install the chart

Helm install `<repo>`/`<chart>` (just like 🐋 ...), the `release name` is an **instance of the helm-chart** in version `x.y.z`.

```sh
helm install my-whoami -f ./deployment/helm/values/whoami/my-whoami.yaml cowboysysop/whoami
```

Shold yield:

```sh
NAME: my-whoami
LAST DEPLOYED: Wed Nov 17 21:11:44 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  http:///
```

### 5️⃣.7 🧪 Let's test  it ! 

Considering our k3d-devcluster is forwarding `80->Loadbalancer:80` we can simply `curl localhost` like so:

```sh
curl localhost
Hostname: my-whoami-987f9cccf-pxp7k
IP: 127.0.0.1
IP: ::1
IP: 10.42.0.18
IP: fe80::6c91:aeff:fe76:fa61
RemoteAddr: 10.42.0.16:50442
GET / HTTP/1.1
Host: localhost
User-Agent: curl/7.64.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 10.42.0.1
X-Forwarded-Host: localhost
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-74dd4975f9-dlp45
X-Real-Ip: 10.42.0.1
```

### 5️⃣.8 Working with existng charts

Getting chart information:

Facts:
1. When you use helm `install / upgrade` helm stores the installation info in a secret in the release namespace.

```sh
kubectl get secret
NAME                              TYPE                                  DATA   AGE
default-token-cbqzl               kubernetes.io/service-account-token   3      25m
my-whoami-token-nppd7             kubernetes.io/service-account-token   3      6m32s
sh.helm.release.v1.my-whoami.v1   helm.sh/release.v1                    1      6m32s
```

2. You can request status of the chart like so:

```sh
helm status my-whoami 
NAME: my-whoami
LAST DEPLOYED: Wed Nov 17 12:11:44 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  http:///
```
3. Getting Chart manifest / values

```sh
helm get values my-whoami
USER-SUPPLIED VALUES:
ingress:
  enabled: true
  hosts:
  - paths:
    - /
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 5️⃣.9 Upgrade [ & Rollback ]


Let's remove some values ...

```yaml
cat<<EOF>./deployment/helm/values/whoami/my-whoami.yaml
ingress:
  enabled: true
  hosts:
    - paths: 
        - /

resources:
  limits:
    cpu: 100m
    memory: 128Mi
EOF
```

UPgrade the release:

```sh
helm upgrade --install my-whoami -f ./deployment/helm/values/whoami/my-whoami.yaml cowboysysop/whoami
```

Should yield:

```sh
Release "my-whoami" has been upgraded. Happy Helming!
NAME: my-whoami
LAST DEPLOYED: Wed Nov 17 21:29:22 2021
NAMESPACE: default
STATUS: deployed
REVISION: 2
NOTES:
1. Get the application URL by running these commands:
  http:///
```

Let's see our values (verify they were overwitten):

```yaml
helm get values my-whoami
USER-SUPPLIED VALUES:
ingress:
  enabled: true
  hosts:
  - paths:
    - /
resources:
  limits:
    cpu: 100m
    memory: 128Mi
```

## Rollback

Helm rollback ... (more like "always forward"):

```sh
helm rollback my-whoami 1
Rollback was a success! Happy Helming!
```

Prove the rollback:

```yaml
helm get values my-whoami
USER-SUPPLIED VALUES:
ingress:
  enabled: true
  hosts:
  - paths:
    - /
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

helm ls shoues the `REVISON` of the `my-whoami` release of `cowboysysop/whoami`:

```sh

NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
my-whoami       default         5               2021-11-17 21:31:09.048263 +0200 EET    deployed        whoami-2.5.1    1.5.0      

```

Charts can be simple / complex - depnding on the composer ;)
In our next 🥼 LAB we will build our own helm chart.

---

🆙 next - [Install Redis via HELM](05-02-redis-chart.md) 
# ping-chart-solution - add configmap + envVar to api


## 🚀 Launch a luster

1. you might need to cleanup ? -> `k3d cluster delete devcluster`

2. Create dev cluster

  k3d cluster create devcluster \
	--api-port 127.0.0.1:6443 \
	-p 80:80@loadbalancer \
	-p 443:443@loadbalancer

## 🔍 Let's review this overrides file together:

```yaml
cat<<EOF>>./deployment/helm/charts/pingalicious/values-init-version.yaml

redis:
  fullnameOverride: redis
  enabled: true
  cluster:
    enabled: false
  image:
    tag: "5.0"
  usePassword: false

containerPort: 8080

image:
  repository: registry.gitlab.com/tikal-external/academy-public/images/nodejs-ping
  tag: 0.1.0

# This will render the the {{ include "pingalicious.fullname" . }} to api -> see the _helpers.tpl file
fullnameOverride: "api"

# this sets the confgFilename to be default.json 
nodeEnv: development

# The configFile name e.g my-file.json will render to configmap
configFilename: development.json

# The json entries ... configJson will populate the my-file.json configmap
configJson:
  redis_host: "redis-master"
  redis_port: 6379

# The ingress configration
ingress:
  enabled: true
  hosts:
    - paths:
        - path: /
          pathType: ImplementationSpecific
```

## Add `templates/configmap.yaml`

Create a configmap named <relase-name>-conf 

```yaml
cat<<EOF>>./deployment/helm/charts/pingalicious/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "pingalicious.fullname" . }}-conf
  labels:
      {{- include "pingalicious.labels" . | nindent 4 }}
data:
  {{ .Values.configFilename }}: |-
{{- toPrettyJson .Values.configJson | nindent 4 }}
EOF
```

## Attach the `configmap` to the <relase-name> `deployment`

In the deployment.yaml template we need to update:

1. `pod` >> `template` >> `spec` >> `volumes` 
1. `pod` >> `template` >> `spec` >> `containers` >> `volumeMounts` 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "pingalicious.fullname" . }}
  # ...
spec:
  # ...
  template:
    metadata:
      # ...
    spec:
      # ...
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          # ...
          # volumeMounts - mount the configmap to the  /opt/tikal/config/{{ .Values.configFilename }}
          volumeMounts:
          - mountPath: /opt/tikal/config/{{ .Values.configFilename }}
            name: config
            # in our case the /opt/tikal/config/ has other files so we want to add / override a specific one only ! 
            subPath: {{ .Values.configFilename }}
      # volumes declared here are attached to the pod template above in volumeMounts
      volumes:
      - name: config
        configMap:
          name: {{ include "pingalicious.fullname" . }}-conf
```

The Full `deployment.yaml` should be now:

```yaml
cat<<EOF>>./deployment/helm/charts/pingalicious/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "pingalicious.fullname" . }}
  labels:
    {{- include "pingalicious.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "pingalicious.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "pingalicious.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "pingalicious.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
            - name: NODE_ENV
              value: {{ .Values.nodeEnv }}
          ports:
            - name: http
              containerPort: {{ .Values.containerPort }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
          - mountPath: /opt/tikal/config/{{ .Values.configFilename }}
            name: config
            subPath: {{ .Values.configFilename }}
      volumes:
      - name: config
        configMap:
          name: {{ include "pingalicious.fullname" . }}-conf
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
```

## Let's apply

```sh
helm upgrade ping-app-dev --install -f ./deployment/helm/charts/pingalicious/values-init-version.yaml ./deployment/helm/charts/pingalicious
```
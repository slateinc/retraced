{{/*
Expand the name of the chart.
*/}}
{{- define "retraced.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "retraced.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "retraced.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "retraced.labels" -}}
helm.sh/chart: {{ include "retraced.chart" . }}
{{ include "retraced.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in matchLabels and pod template labels.
Each deployment adds app.kubernetes.io/component inline to ensure unique selection.
*/}}
{{- define "retraced.selectorLabels" -}}
app.kubernetes.io/name: {{ include "retraced.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Build a full image reference, respecting global.imageRegistry as a pull-through cache prefix.
Usage: {{ include "retraced.image" (dict "image" .Values.api.image "global" .Values.global "default" .Chart.AppVersion) }}
*/}}
{{- define "retraced.image" -}}
{{- $registry := "" -}}
{{- with .global -}}
{{- $registry = .imageRegistry | default "" -}}
{{- end -}}
{{- $tag := .image.tag | default .default -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry .image.repository $tag -}}
{{- else -}}
{{- printf "%s:%s" .image.repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Name of the non-sensitive config ConfigMap.
*/}}
{{- define "retraced.configMapName" -}}
{{- include "retraced.fullname" . }}-config
{{- end }}

{{/*
Name of the credentials Secret.
*/}}
{{- define "retraced.credentialsSecretName" -}}
{{- include "retraced.fullname" . }}-credentials
{{- end }}

{{/*
Name of the bootstrap Secret.
*/}}
{{- define "retraced.bootstrapSecretName" -}}
{{- include "retraced.fullname" . }}-bootstrap
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "retraced.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "retraced.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Checksum annotations for pod templates. Forces a rolling restart when the
ConfigMap or credentials Secret changes.
*/}}
{{- define "retraced.checksumAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/auditlog-secret.yaml") . | sha256sum }}
{{- end }}

{{/*
Name of the admin portal config ConfigMap.
*/}}
{{- define "retraced.adminConfigMapName" -}}
{{- include "retraced.fullname" . }}-admin-config
{{- end }}

{{/*
Name of the admin portal credentials Secret.
*/}}
{{- define "retraced.adminCredentialsSecretName" -}}
{{- include "retraced.fullname" . }}-admin-credentials
{{- end }}

{{/*
envFrom block for the admin portal pod.
*/}}
{{- define "retraced.adminEnvFrom" -}}
- configMapRef:
    name: {{ include "retraced.adminConfigMapName" . }}
{{- if .Values.admin.credentials.createSecret }}
- secretRef:
    name: {{ include "retraced.adminCredentialsSecretName" . }}
{{- end }}
{{- with .Values.admin.extraEnvFrom }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Standard envFrom block used by all application pods.
Mounts the config ConfigMap, the credentials Secret, and any user-supplied extraEnvFrom sources.
*/}}
{{- define "retraced.envFrom" -}}
- configMapRef:
    name: {{ include "retraced.configMapName" . }}
- secretRef:
    name: {{ include "retraced.credentialsSecretName" . }}
{{- with .Values.extraEnvFrom }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

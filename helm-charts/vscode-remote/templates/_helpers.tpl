{{/*
Expand the name of the chart.
*/}}
{{- define "vscode-remote.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vscode-remote.fullname" -}}
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
{{- define "vscode-remote.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vscode-remote.labels" -}}
helm.sh/chart: {{ include "vscode-remote.chart" . }}
{{ include "vscode-remote.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vscode-remote.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vscode-remote.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vscode-remote.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vscode-remote.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the profile file to sev envs
*/}}
{{- define "vscode-remote.profileScript" -}}
# eval $(/usr/bin/locale-check C.UTF-8)
export KUBECONFIG=/home/vscode/.kubeconfig/kubeconfig
{{- range $name, $value := .Values.envs }}
export {{ $name }}={{ $value }}
{{- end }}
{{- end }}

{{/*
Renders a volumeClaimTemplate.
Usage:
{{ include "volumeClaimTemplate.render" .Values.persistence }}
*/}}
{{- define "volumeClaimTemplate.spec.render" -}}
spec:
  accessModes:
  {{- range .accessModes }}
    - {{ . | quote }}
  {{- end }}
  resources:
    requests:
      storage: {{ .size | quote }}
{{- if .storageClass }}
{{- if (eq "-" .storageClass) }}
  storageClassName: ""
{{- else }}
  storageClassName: "{{ .storageClass }}"
{{- end }}
{{- end }}
{{- end -}}

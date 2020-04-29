{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rosent-pv.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rosent-pv.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rosent-pv.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "rosent-pv.labels" -}}
helm.sh/chart: {{ include "rosent-pv.chart" . }}
{{ include "rosent-pv.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.rosentimage.imageVersion }}
rosent-version: {{ .Values.rosentimage.imageVersion }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "rosent-pv.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rosent-pv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.environment }}
env: {{ .Values.environment }}
{{- end }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "rosent-pv.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "rosent-pv.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

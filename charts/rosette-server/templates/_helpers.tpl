{{/*
Expand the name of the chart.
*/}}
{{- define "rosette-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rosette-server.fullname" -}}
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
{{- define "rosette-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rosette-server.labels" -}}
helm.sh/chart: {{ include "rosette-server.chart" . }}
{{ include "rosette-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels (Used in hooks podAffinity, before changing make sure it will still work with them)
*/}}
{{- define "rosette-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rosette-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rosette-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rosette-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a separator string for roots config override scripts to work with
*/}}
{{- define "hooks-separator-string" -}}
{{- if .Values.rootsOverride.separator }}
{{- print .Values.rootsOverride.separator }}
{{- else }}
{{- print "&&&" }}
{{- end }}
{{- end }}

{{/*
Create initContainer image name, or use Rosette Serve's if one is not provided
*/}}
{{- define "initContainer-image" -}}
    {{- if .Values.initContainer.image -}}
        {{- if .Values.initContainer.tag -}}
            {{ print .Values.initContainer.image ":" .Values.initContainer.tag }}
        {{- else -}}
            {{ print .Values.initContainer.image }}
        {{- end -}}
    {{- else -}}
    {{- print  .Values.image.repository ":" ( default .Values.image.tag .Chart.AppVersion ) }}
    {{- end }}
{{- end }}

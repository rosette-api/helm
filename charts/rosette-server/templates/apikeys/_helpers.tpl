{{/*
Create the name of the service account to use
*/}}
{{- define "rosette-server-apikeys.serviceAccountName" -}}
{{- if .Values.apikeys.serviceAccount.create }}
{{- default (include "rosette-server.fullname" .) .Values.apikeys.serviceAccount.name }}-apikeys-db-sa
{{- else }}
{{- default "default" .Values.apikeys.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Always define a non empty database name for api keys
*/}}
{{- define "apikeys-database-name" -}}
    {{- default "apikeys" .Values.apikeys.dbName }}
{{- end }}


{{/*
Create an environment section for the DB_USER, DB_PASSWORD, DB_NAME, APIKEYS_URL variables. If the secret is not set, defaults are used for the credential variables
*/}}
{{- define "apikeys-database-env-variables" -}}
{{- $podDNSformat := printf "%s-apikeys-db-server-%%d.%s-apikeys-db.%s.svc.%s" (include "rosette-server.fullname" .) (include "rosette-server.fullname" .) .Release.Namespace .Values.apikeys.clusterDomain -}}
- name: APIKEYS_URL
  value: {{ printf "%s:9092,%s:9092" (printf $podDNSformat 0) (printf $podDNSformat 1) }}
- name: DB_NAME
  value: {{ include "apikeys-database-name" . }}
{{- if .Values.apikeys.dbAccessSecretName }}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.apikeys.dbAccessSecretName }}
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.apikeys.dbAccessSecretName }}
      key: password
{{- else }}
- name: DB_USER
  value: rosette-server-helm
- name: DB_PASSWORD
  value: rosette-server-helm
{{- end }}
{{- end }}

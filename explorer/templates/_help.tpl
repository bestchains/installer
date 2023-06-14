{{- define "pg-svc" -}}
{{- if .Values.runtimeArgs.pgAddr }}
{{- printf .Values.runtimeArgs.pgAddr -}}
{{- else }}
{{- printf "postgres://bestchains:Passw0rd!@%s-postgresql.%s.svc.cluster.local:5432/bestchains?sslmode=disable" .Release.Name .Release.Namespace -}}
{{- end -}}
{{- end -}}
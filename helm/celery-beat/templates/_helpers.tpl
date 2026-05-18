{{- define "celery-beat.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "celery-beat.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "celery-beat.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "celery-beat.labels" -}}
helm.sh/chart: {{ include "celery-beat.chart" . }}
{{ include "celery-beat.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "celery-beat.selectorLabels" -}}
app.kubernetes.io/name: {{ include "celery-beat.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

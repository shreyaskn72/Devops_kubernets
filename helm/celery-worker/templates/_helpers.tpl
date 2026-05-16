{{- define "celery-worker.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "celery-worker.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "celery-worker.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "celery-worker.labels" -}}
helm.sh/chart: {{ include "celery-worker.chart" . }}
{{ include "celery-worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "celery-worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "celery-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

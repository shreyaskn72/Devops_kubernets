{{- define "flower.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "flower.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "flower.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "flower.labels" -}}
helm.sh/chart: {{ include "flower.chart" . }}
{{ include "flower.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "flower.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flower.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

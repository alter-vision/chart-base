{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "base.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if $.Values.base.fullnameOverride -}}
{{- $.Values.base.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Same as base.fullname but $name and .Release.Name are separated by "/"
in case of .Release.Name
*/}}
{{- define "base.fullnameForImage" -}}
{{- if .Values.fullnameForImageOverride -}}
{{- .Values.fullnameForImageOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s/%s" $name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*  Manage the labels for each entity  */}}
{{- define "base.labels" -}}
app: {{ template "base.name" . }}
fullname: {{ template "base.fullname" . }}
chart: {{ template "base.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- range $key, $val := .Values.additionalLabels }}
{{ $key }}: {{ $val | quote }}
{{- end -}}
{{- end -}}

{{/*  Get configMap from file for using from parent chart (note .Values.base.containers)  */}}
{{- define "base.cm.fromfile" -}}
{{- $root := . -}}
{{- range $containerName, $containerValues := .Values.base.containers -}}
{{- range $cm := $containerValues.configMapsFromFiles }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "base.fullname" $root }}-{{ $containerName }}-{{ regexReplaceAll "[^a-zA-Z0-9]" (regexReplaceAll "^/" $cm.mountPath "") "-" }}
  labels:
{{ include "base.labels" $root | indent 4 }}
binaryData:
  {{ $cm.fileName }}: {{ $root.Files.Get (printf "files/%s" $cm.fileName) | b64enc }}
{{ end -}}
{{- end -}}
{{- end }}


{{/* Detect if any service is enabled */}}
{{- define "hasServiceMonitor" -}}
  {{- $_hasServiceMonitor := "disabled" -}}
  {{- range $port_name, $port_values := .Values.servicePorts -}}
    {{- if eq (default "disabled" $port_values.serviceMonitor) "enabled" -}}
      {{- $_hasServiceMonitor = "enabled" -}}
    {{- end -}}
  {{- end -}}
  {{- printf $_hasServiceMonitor -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "base.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "base.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Set apiversion for workload resources based on k8s version
*/}}
{{- define "base.k8sVersion" -}}
{{- printf "%s.%s" .Capabilities.KubeVersion.Major (replace "+" "" .Capabilities.KubeVersion.Minor) -}}
{{- end -}}

{{/*
Set Ingress apiVersion based on k8sVersion
*/}}
{{- define "base.ingressApiVersion" -}}
{{- $k8sVersion := include "base.k8sVersion" . -}}
{{- printf "%s" (ternary "networking.k8s.io/v1" "networking.k8s.io/v1beta1" (.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress")) -}}
{{- end -}}

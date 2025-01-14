{{/*
Template that creates a list of containers for root extraction based on enabledEndpoints and enabledLanguages
*/}}
{{- define "rosette.root-extraction.containers" -}}
{{- $imageRepository := print (include "rosette-server.image.registry" (merge (dict "defaultRegistry" "") .)) $.Values.rootsImageRepository -}}
{{- if not (hasSuffix "/" $imageRepository) -}}
    {{- $imageRepository = print $imageRepository "/" -}}
{{- end -}}
# These roots cover, language, morph, sent, tokens
- name: {{ .Release.Name }}-populate-rli
  image: {{ print $imageRepository "root-rli:" .Values.roots.version.rli | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
- name: {{ .Release.Name }}-populate-rbl
  image: {{ print $imageRepository "root-rbl:" .Values.roots.version.rbl | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
    {{- $installedRoots := list -}}
    {{- range $ep := .Values.enabledEndpoints -}}
        {{- if or (eq $ep "entities") (eq $ep "events") (eq $ep "topics") (eq $ep "relationships") (eq $ep "sentiment") }}
            {{- if not (has "rex" $installedRoots) }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-rex-root:" $.Values.roots.version.rex | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                {{- range $lang := $.Values.enabledLanguages -}}
                    {{- $entitiesLanguages := list "ara" "deu" "eng" "fas" "fra" "heb" "hun" "ita" "ind" "jpn" "kor" "nld" "por" "pus" "rus" "spa" "swe" "tgl" "urd" "vie" "zho" "zsm" }}
                    {{- if has $lang $entitiesLanguages }}
- name: {{ $.Release.Name }}-populate-rex-{{$lang}}
  image: {{ print $imageRepository "root-rex-" $lang ":" $.Values.roots.version.rex | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                    {{- end }}
                {{- end }}
                {{- $installedRoots = append $installedRoots "rex" -}}
            {{- end }}
        {{- end }}
        {{- if eq $ep "categories" }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-tcat:" $.Values.roots.version.tcat | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
        {{- end }}
        {{- if or (eq $ep "name-translation") (eq $ep "name-similarity") (eq $ep "name-deduplication") (eq $ep "address-similarity") (eq $ep "record-similarity") }}
            {{- if not (has "names" $installedRoots) }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-rni-rnt:" $.Values.roots.version.rnirnt | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                {{- $installedRoots = append $installedRoots "names" -}}
            {{- end }}
        {{- end }}
        {{- if eq $ep "sentiment" }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-ascent:" $.Values.roots.version.ascent | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
        {{- end }}
        {{- if or (eq $ep "syntax/dependencies") (eq $ep "relationships") }}
            {{- if not (has "nlp4j" $installedRoots) }}
- name: {{ print $.Release.Name "-populate-" "nlp4j" | quote }}
  image: {{ print $imageRepository "root-nlp4j:" $.Values.roots.version.nlp4j | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                {{- $installedRoots = append $installedRoots "nlp4j" -}}
            {{- end }}
        {{- end }}
        {{- if eq $ep "transliteration" }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-rct:" $.Values.roots.version.rct | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
        {{- end }}
        {{- if eq $ep "relationships" }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-relax:" $.Values.roots.version.relax | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
        {{- end }}
        {{- if  or (eq $ep "topics") (eq $ep "events") }}
            {{- if not (has "topics" $installedRoots) }}
- name: {{ print $.Release.Name "-populate-" $ep | quote }}
  image: {{ print $imageRepository "root-topics:" $.Values.roots.version.topics | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                {{- $installedRoots = append $installedRoots "topics" -}}
            {{- end }}
        {{- end }}
        {{- if or (eq $ep "semantics/similar") (eq $ep "semantics/vector") }}
            {{- if not (has "tvec" $installedRoots) }}
                {{- range $lang := $.Values.enabledLanguages -}}
                    {{- $vectorLanguages := list "ara" "deu" "eng" "fas" "fra" "heb" "hun" "ita" "jpn" "kor" "por" "qkp" "rus" "spa" "tgl" "urd" "zho" }}
                    {{- if has $lang $vectorLanguages }}
- name: {{ $.Release.Name }}-populate-vec-{{$lang}}
  image: {{ print $imageRepository "root-tvec-" $lang ":" $.Values.roots.version.tvec | quote }}
  volumeMounts:
    - mountPath: "/roots-vol"
      name: {{ $.rootsVolumeName }}
                    {{- end }}
                {{- end }}
                {{- $installedRoots = append $installedRoots "tvec" -}}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
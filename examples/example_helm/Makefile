# Adds generated file as a dependency for various targets
EMBEDS += kube-prometheus-stack.yaml

include ../Makefile.default

# Run `helm template`. values.yaml is created by a generic .cue -> .yaml rule
rendered.yaml: values.yaml
	@helm template prometheus \
		--repo https://prometheus-community.github.io/helm-charts \
			kube-prometheus-stack \
			--version='^80' \
			--namespace=monitoring \
			--values=$< > $@

# Mark generated files as intermediate so that they aren't created unless needed.
.INTERMEDIATE: values.yaml rendered.yaml

# Post-process YAML output to allow CUE to parse it.
kube-prometheus-stack.yaml: rendered.yaml cleanup.jq
	@yq --yaml-roundtrip -f cleanup.jq $< \
		| sed -E -e 's/crds.bz2:/crds.bz2: !!binary/' > $@

clean::
	@-rm kube-prometheus-stack.yaml

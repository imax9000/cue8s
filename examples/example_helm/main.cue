@extern(embed)

package examplehelm

import (
	"imax.in.ua/cue8s/helm"

	"cluster.home.arpa/base"
)

base

({
	helm.processManifests

	yamlText:      _ @embed(file=kube-prometheus-stack.yaml, type=text)
	namespace:     "monitoring"
	importedKinds: base.#importKinds
}).result

monitoring: deployment: {
	// Imported manifests can be unified with as usual.
	"prometheus-kube-prometheus-operator": {
		labels: foo: "bar"
	}
}

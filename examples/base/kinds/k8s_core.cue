package kinds

import (
	corev1 "cue.dev/x/k8s.io/api/core/v1"
)

#importKinds: import_k8s_corev1: {
	apiVersion: "v1"
	namespaced: [
		["configMap", "ConfigMap", corev1.#ConfigMap],
		["service", "Service", corev1.#Service],
		["secret", "Secret", corev1.#Secret],
		["pvc", "PersistentVolumeClaim", corev1.#PersistentVolumeClaim],
		["pod", "Pod", corev1.#Pod],
		["serviceAccount", "ServiceAccount", corev1.#ServiceAccount],
	]
	global: [
		["namespace", "Namespace", corev1.#Namespace],
		["persistentVolume", "PersistentVolume", corev1.#PersistentVolume],
		["node", "Node", corev1.#Node],
	]
}

#namespacedResourceKinds: secret: #template: self={
	stringData: *null | {[string]: string}
	type: *"Opaque" | corev1.#enumSecretType

	k8s: {
		type: self.type
		if stringData != null {
			stringData: self.stringData
		}
	}
}

#namespacedResourceKinds: configMap: #template: self={
	immutable: *false | bool
	data: [string]:       string
	binaryData: [string]: bytes

	k8s: {
		if self.immutable {
			immutable: self.immutable
		}
		if len(self.data) > 0 {
			data: self.data
		}
		if len(self.binaryData) > 0 {
			binaryData: self.binaryData
		}
	}
}

#namespacedResourceKinds: service: #template: self={
	selector: [string]: string
	ports: [_]:         _
	type: *"ClusterIP" | string

	k8s: spec: {
		type: self.type

		if len(self.ports) > 0 {
			ports: [
				for _k, _v in self.ports {
					{name: _k} & _v
				},
			]
		}
		if len(self.selector) > 0 {
			selector: self.selector
		}
	}
}

package kinds

import (
	appsv1 "cue.dev/x/k8s.io/api/apps/v1"
	corev1 "cue.dev/x/k8s.io/api/core/v1"
)

#importKinds: import_appsv1: {
	apiVersion: "apps/v1"
	namespaced: [
		["statefulSet", "StatefulSet", appsv1.#StatefulSet],
		["deployment", "Deployment", appsv1.#Deployment],
		["daemonSet", "DaemonSet", appsv1.#DaemonSet],
	]
}

_setReplicas: self={
	replicas: >=0
	replicas: *1 | int

	k8s: spec: replicas: self.replicas
}

_setMatchLabels: self={
	matchLabels: name:     *self.name | string | null
	matchLabels: [string]: string

	k8s: spec: {
		selector: matchLabels: self.matchLabels
		template: metadata: labels: self.matchLabels
	}
}

_setVolumes: self={
	volumes: [string]: _

	if len(volumes) > 0 {
		k8s: spec: template: spec: volumes: [for _k, _v in self.volumes {
			{name: _k} & _v
		}]
	}
}

_setContainers: self={
	containers: [_name=string]: {
		corev1.#Container

		name: *_name | string

		#params: {
			ports: [string]:        _
			env: [string]:          _
			volumeMounts: [string]: _
		}

		if len(#params.ports) > 0 {
			ports: [for _k, _v in #params.ports {
				{name: _k} & _v
			}]
		}
		if len(#params.env) > 0 {
			env: [for _k, _v in #params.env
				let _isString = (_v & string) != _|_
				let _isStringable = "\(_v)" != _|_ {
					{name: _k}
					[
						if _isString {value: _v},
						if _isStringable {value: "\(_v)"},
						_v,
					][0]
				}]
		}
		if len(#params.volumeMounts) > 0 {
			volumeMounts: [for _k, _v in #params.volumeMounts {
				{mountPath: _k} & _v
			}]
		}
	}

	if len(containers) > 0 {
		k8s: spec: template: spec: containers: [for _k, _v in self.containers {
			{name: _k} & _v
		}]
	}
}

_setRuntimeClass: self={
	runtimeClassName: string | *null

	if self.runtimeClassName != null {
		k8s: spec: template: spec: runtimeClassName: self.runtimeClassName
	}
}

#namespacedResourceKinds: deployment: #template: {
	_setReplicas
	_setMatchLabels
	_setVolumes
	_setContainers
	_setRuntimeClass
}

#namespacedResourceKinds: statefulSet: #template: {
	_setReplicas
	_setMatchLabels
	_setVolumes
	_setContainers
	_setRuntimeClass
}

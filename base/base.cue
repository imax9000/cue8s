package base

import (
	"list"
)

_objectBase: self={
	name: string
	labels: [string]:      string
	annotations: [string]: string

	k8s: {
		#TypeMeta

		metadata: {
			#ObjectMeta

			name: self.name
			if len(self.labels) > 0 {
				labels: self.labels
			}
			if len(self.annotations) > 0 {
				annotations: self.annotations
			}
		}
	}
}

_clusterWideResource: {_objectBase}

_namespacedResource: self={
	_objectBase

	namespace: string

	k8s: metadata: namespace: self.namespace
}

_allValuesAreValidStructs: [_]: self={
	*{} | error("<- invalid object (check other error messages)\(self)")
}

_setTypeMeta: self={
	#apiVersion!: string
	#kind!:       string

	#template: k8s: {
		apiVersion: self.#apiVersion
		kind:       self.#kind
	}
}

_resourceKindsBase: {
	#util: {...}
	_base!: _

	#allowedCharacterSet:    =~"^[.a-z0-9-]+$"
	#upTo63Characters:       =~"^.{1,63}$"
	#startsWithALetter:      =~"^[a-z]"
	#endsWithALetterOrDigit: =~"[a-z0-9]$"

	[string]: {
		_allValuesAreValidStructs
		_setTypeMeta
		#resourceSchema: _

		#template: {
			// Thanks to embedding, #resourceSchema is allowed to
			// add new fields not present in _base.
			_base

			k8s: #resourceSchema
		}
		[ID=#allowedCharacterSet &
			#upTo63Characters &
			#startsWithALetter &
			#endsWithALetterOrDigit]: {#template, name: ID}

		[ID=_]: {
			if ((ID & #allowedCharacterSet &
				#upTo63Characters &
				#startsWithALetter &
				#endsWithALetterOrDigit) == _|_) {
				error("invalid resource name: \(ID)")
			}
		}
	}
}

#namespacedResourceKinds: {
	_resourceKindsBase
	#util: knownFields: [for f, _ in #namespacedResourceKinds {f}]

	_base: _namespacedResource

	[string]: [string]: namespace: #util.namespace
}

#clusterWideResourceKinds: {
	_resourceKindsBase
	#util: knownFields: [for f, _ in #clusterWideResourceKinds {f}]

	_base: _clusterWideResource
}

#namespace: #namespacedResourceKinds & {
	#util: #namespacedResourceKinds.#util
	[kind=string]: {
		_knownKind: list.Contains(#util.knownFields, kind)
		[
			if !_knownKind {
				error("<- object kind not defined in the base package")
			},
			_,
		][0]
	}
}

#global: #clusterWideResourceKinds & {
	#util: #clusterWideResourceKinds.#util
	[kind=string]: {
		_knownKind: list.Contains(#util.knownFields, kind)
		[
			if !_knownKind {
				error("<- object kind not defined in the base package")
			},
			_,
		][0]
	}
}

[_NS=string & !="global" & !="export"]: #namespace & {#util: namespace: _NS}
global: #global & {#util: namespace: "global"}

package base

_makeKinds: self={
	_apiVersion!: string

	[string]: #apiVersion: _apiVersion
	_entries: {
		for k, v in self {(k): v}
	}
	// [fieldName, kind, schema]
	_kinds: [
		...[string, string, {}],
	]

	for _kind in _kinds {
		(_kind[0]): {
			#kind:           _kind[1]
			#resourceSchema: _kind[2]
		}
	}
}

#importKinds: [string]: close({
	apiVersion: string
	namespaced: _makeKinds._kinds
	global:     _makeKinds._kinds

	_namespaced: _makeKinds & {
		_apiVersion: apiVersion
		_kinds:      namespaced
	}
	_global: _makeKinds & {
		_apiVersion: apiVersion
		_kinds:      global
	}
})

for _imported in #importKinds {
	#namespacedResourceKinds:  _imported._namespaced._entries
	#clusterWideResourceKinds: _imported._global._entries
}

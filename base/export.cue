package base

import (
	"encoding/yaml"
)

#export: {
	#entries: [...]
	manifests: [
		for _entry in #entries
		for _ns in _entry
		for _kind, _objs in _ns
		for _name, _obj in _objs {
			_obj.k8s
		}]
	yamlStream: yaml.MarshalStream(manifests)
}

package helm

import (
	"encoding/yaml"
	"list"
)

processManifests: self={
	// Inputs
	yamlText!:     string
	namespace:     string | *null
	importedKinds: _

	// Configuration
	knownGlobalKinds: [string]: bool

	// Output
	result: _

	// Implementation
	_rawManifests: yaml.UnmarshalStream(yamlText)

	for _i, _m in _rawManifests {
		result: ({
			resolvedKind: {
				_helpers.lookupKind
				kind: _m.kind
			}

			// `helm template` deliberately doesn't set
			// `metadata.namespace` field if user templates don't
			// generate it, relying on `kubectl` to set it appropriately.
			// Since we need to the namespace to know which
			// top-level field to use, we must deduce it ourselves.
			// Additional complication is that we need additional
			// side-channel to know if a given resource kind
			// is namespaced or not. `kubectl` gets that information
			// by querying kube-apiserver. But we can't really do that,
			// so instead we let the user specify which kinds
			// are to be treated as not namespaced, with common
			// core and *.k8s.io kinds already taken care of.
			topLevelField: [
				if resolvedKind.global == true {"global"},
				if "\(_m.metadata.namespace)" != _|_ {_m.metadata.namespace},
				if "\(self.namespace)" != null {self.namespace},
			][0]

			result: (topLevelField): (resolvedKind.fieldName): {
				[
					if resolvedKind.fieldName == "nonValidated" {
						// `nonValidated` contains resources of different kinds,
						// so to avoid name collisions we put
						// kind in the field name too.
						"\(_m.kind):\(_m.metadata.name)": k8s: _m
					},

					{(_m.metadata.name): k8s: _m},
				][0]
			}
		}).result
	}

	_helpers: lookupKind: {
		kind: string

		fieldName: string
		global:    bool

		_tmp: [
			for _k, _v in importedKinds
			for _item in _v.namespaced
			if _item[1] == kind {
				fieldName: _item[0]
				global:    false
			},

			for _k, _v in importedKinds
			for _item in _v.global
			if _item[1] == kind {
				fieldName: _item[0]
				global:    true
			},

			if list.Contains(_globalKindsList, kind) {
				fieldName: "nonValidated"
				global:    true
			},

			{
				fieldName: "nonValidated"
				global:    false
			},
		]
		// Doing [...][0] in one go here sometimes results in weird errors.
		_tmp[0]
	}

	_globalKindsList: [
		for _k, _v in knownGlobalKinds
		if _v {
			_k
		},
	]
}

processManifests: knownGlobalKinds: {
	// v1
	Namespace: true
	Node:      true

	// admissionregistration.k8s.io/v1
	MutatingWebhookConfiguration:     true
	ValidatingAdmissionPolicy:        true
	ValidatingAdmissionPolicyBinding: true
	ValidatingWebhookConfiguration:   true

	// apiextensions.k8s.io/v1
	CustomResourceDefinition: true

	// apiregistration.k8s.io/v1
	APIService: true

	// authentication.k8s.io/v1
	SelfSubjectReview: true
	TokenReview:       true

	// authorization.k8s.io/v1
	SelfSubjectAccessReview: true
	SelfSubjectRulesReview:  true
	SubjectAccessReview:     true

	// certificates.k8s.io/v1
	CertificateSigningRequest: true

	// flowcontrol.apiserver.k8s.io/v1
	FlowSchema:                 true
	PriorityLevelConfiguration: true

	// gateway.networking.k8s.io/v1
	GatewayClass: true

	// metrics.k8s.io/v1beta1
	NodeMetrics: true

	// networking.k8s.io/v1
	IngressClass: true
	IPAddress:    true
	ServiceCIDR:  true

	// node.k8s.io/v1
	RuntimeClass: true

	// policy.networking.k8s.io/v1alpha1
	AdminNetworkPolicy:         true
	BaselineAdminNetworkPolicy: true

	// rbac.authorization.k8s.io/v1
	ClusterRoleBinding: true
	ClusterRole:        true

	// scheduling.k8s.io/v1
	PriorityClass: true

	// snapshot.storage.k8s.io/v1
	VolumeSnapshotClass:   true
	VolumeSnapshotContent: true

	// storage.k8s.io/v1
	CSIDriver:        true
	CSINode:          true
	StorageClass:     true
	VolumeAttachment: true
}

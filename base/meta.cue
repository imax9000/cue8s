package base

// These are here just to avoid a dependency on any particular
// version/variation of k8s.io/apimachinery/pkg/apis/meta/v1

#TypeMeta: {
	kind?:       string
	apiVersion?: string
}

#ObjectMeta: {
	name?:                       string
	generateName?:               string
	namespace?:                  string
	selfLink?:                   string
	uid?:                        string
	resourceVersion?:            string
	generation?:                 int64
	creationTimestamp?:          _
	deletionTimestamp?:          null | _
	deletionGracePeriodSeconds?: null | int64
	labels?: [string]:      string
	annotations?: [string]: string
	ownerReferences?: [...]
	finalizers?: [...string]
	managedFields?: [...]
}

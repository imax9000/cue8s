# cue8s

[CUE](https://cuelang.org) template for rendering Kubernetes manifests.

I've been using it for a few months now and am generally satisfied with how it
works. Among the features I've been specifically looking for:

* Not having to repeat `namespace: "..."` in each object
* Strict validation: if I make a typo, I want `cue` to yell at me, rather then
  waste time debugging why a change had no effect
* Ability to incrementally improve templates for each resource kind

## See it in action

```cue
// Resources are structured as follows:
//
// <namespace>: <kind>: <name>: {...}
//
// That is, every top-level field is treated as a namespace. Except for `global`,
// which contains cluster-wide resources. Yes, it means that having a namespace
// called "global" is not supporter, hope you can live with that.

// Create a namespace:
global: namespace: default: {}
// For a namespace it's perfectly fine to have no additional parameters besides
// the name, and `metadata.name` is automatically set to "default".

// This will create a secret named "test" in the namespace "default".
default: secret: test: {
  // `k8s` field is what actually gets rendered into YAML and validated against
  // resource schema. Other fields are for you to use for templating.
  k8s: spec: stringData: {
    foo: "bar"
  }
}

// With custom templating you can have something like this, for example:
default: service: example: {
  // Nothing fancy, it's just copied into `k8s.spec.selector`
  selector: app: "example"

  // Struct of ports by name is translated into an array `k8s.spec.ports`, with
  // `name` set to the name of the field.
  ports: http: {
    port:       80
    targetPort: 8080
  }
}

```

There's a bit of a setup required to get this to work.

## Usage

You need to have a CUE module and add a dependency on this module:

```sh
$ cue mod init <module_name>
$ CUE_REGISTRY=imax.in.ua/cue8s=ghcr.io/imax9000/cue8s cue mod get imax.in.ua/cue8s
```

Then, you need to import the package and embed it in the top-level scope:

```cue
import (
  "imax.in.ua/cue8s/base"
)

base
```

To introduce resource kinds you need to use `#importKinds` field:

```cue
import (
  corev1 "cue.dev/x/k8s.io/api/core/v1"
)

#importKinds: import_k8s_corev1: {
  // This goes directly into `apiVersion` field.
  apiVersion: "v1"

  namespaced: [
    // First value is the field name you would use in your CUE code,
    // second goes directly into `kind` field in the resulting YAML,
    // third is a schema to validate the manifest.
    ["secret", "Secret", corev1.#Secret],
    ["service", "Service", corev1.#Service],
  ]
  global: [
    ["namespace", "Namespace", corev1.#Namespace],
  ]
}
```

With just this you can already write code that fills in fields under `k8s`. To
make it more ergonomic you can also add your own templating to each resource
type:

```cue
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
```

It is a good idea to put all this into your own `base` package and then import
it in each of your leaf packages.

You can take a look at a functioning setup in the [examples](examples/)
directory.

### Rendering

Getting YAML manifests out of this is a little bit tricky. To iterate over
top-level fields we need to have a name that references the top-level scope.

One way to do that is to have another package that imports the target.
Fortunately, it's possible to create the importing package by passing the code
via stdin:

```sh
cat <<-EOF | cue export --out=text -
package export

import (
  pkg "${target_package}"
)

// `#export` is provided by `imax.in.ua/cue8s/base`, it does the heavy-lifting
// of combing through `pkg`'s content and exposing serialized manifests through
// `yamlStream` field.
_tmp: {pkg.#export, #entries: [pkg]}
_tmp.yamlStream
EOF
```

[eval.sh](examples/eval.sh) script encapsulates this, and
[this Makefile](examples/Makefile) is an example of invoking it on a tree of
directories.

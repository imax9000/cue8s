# Example of a pre-rendered Helm chart

## Prerequisites

Because the Helm chart is rendered ahead of time, your deployment system must
handle [Helm hook annotations](https://helm.sh/docs/topics/charts_hooks) without
running Helm, when they are present on raw manifests. Otherwise any but simplest
charts will not deploy correctly: hook resources will not be deployed in the
correct order and will not get removed when they should.

[Argo CD](https://github.com/argoproj/argo-cd) does this. If you're using
something else - please verify if it works correctly (e.g., by creating a dummy
ConfigMap manifest with hook annotations and checking how it behaves.)

## Build process

Most of the work is done by the build system, CUE code then just imports YAML
manifests and merges them together with the rest of CUE configs.

### Step 1: values file

`values.cue` serves as a source. Note that it doesn't have a `package` line, so
it's ignored by most of `cue` subcommands unless mentioned explicitly as a file
path. It can still import other packages as usual though.

Gets converted to YAML with a simple `cue export --out=yaml values.cue > values.yaml`

### Step 2: render the Helm chart

See [`Makefile`](Makefile) for the specific `helm template` invocation.

One useful trick here is to use `--repo` argument: you can just provide the URL
directly and avoid having to do `repo add` and `repo update`.

### Step 3: post-process Helm output

Before [`main.cue`](main.cue) can use the generated manifests, they need to be
processed a bit for a couple reasons:

1. Fixing import errors. Most common one is a type mismatch between `null` and
    a list when Helm output mentiones a field but doesn't have any list entries
    to go into it.
2. Deleting any fields you want to specify in CUE. YAML is imported as concrete
    values and CUE doesn't have a good way of overriding them.

Here this is done by running [`yq`](https://github.com/kislyuk/yq) with
[`cleanup.jq`](cleanup.jq) script.

### Step 4: importing into CUE

[`main.cue`](main.cue) embeds YAML as text and passes it to a helper template
that does the processing. Imported manifests end up in the same place in the
hierarchy as if they were written directly in CUE. E.g., Prometheus Operator
deployment is put into `monitoring.deployment."prometheus-kube-prometheus-operator".k8s`.

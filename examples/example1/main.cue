package example1

import (
	"cluster.home.arpa/base"
)

// This needs to be done once in every dir.
base

global: namespace: default: {}

default: {
	service: example: {
		selector: app: "example"
		ports: http: {
			port:       80
			targetPort: 8080
		}
	}

	deployment: example: {
		// Can directly reference service selector to avoid repeating labels.
		matchLabels: service.example.selector

		containers: main: {
			image: "image"
			#params: ports: http: containerPort: 8080
		}
	}
}

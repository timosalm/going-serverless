


## Container image building with kpack

```
export REGISTRY_HOST=harbor.main.emea.end2end.link/going-serverless
kp image create inclusion --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/inclusion --env BP_JVM_VERSION=17
```

## Running the application on Knative
```
kn service create inclusion --image $REGISTRY_HOST/inclusion
kubectl logs -l app=inclusion-00001 -c user-container | grep "Started InclusionApplication"
# Started InclusionApplication in 9.534 seconds (process running for 10.477)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe inclusion -o url)
kubectl top pods -l app=inclusion-00001 --containers
# POD                                           NAME             CPU(cores)   MEMORY(bytes)
# inclusion-00001-deployment-86b7c5fdd4-hgjsg   user-container   2m           404Mi
```
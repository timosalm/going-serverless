
## Container image building

```
export REGISTRY_HOST=harbor.main.emea.end2end.link/going-serverless
```

### Project CraC

```
docker build . -t $REGISTRY_HOST/inclusion-crac:checkpointer --file crac/Dockerfile
docker run -d --cap-add CHECKPOINT_RESTORE --cap-add SYS_PTRACE --rm --name inclusion-crac-checkpointer $REGISTRY_HOST/inclusion-crac:checkpointer
# Wait until checkpoint creation succeeded: docker logs $(docker ps -qf "name=inclusion-crac-checkpointer") -f
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=inclusion-crac-checkpointer") $REGISTRY_HOST/inclusion-crac
docker kill $(docker ps -qf "name=inclusion-crac-checkpointer")
# Test: docker run -d --cap-add CHECKPOINT_RESTORE --cap-add SYS_ADMIN --rm -p 8080:8080 --name inclusion-crac-checkpoint $REGISTRY_HOST/inclusion-crac
```

## Container image building with kpack

### Without optimizations
```
kp image create inclusion --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/inclusion --env BP_JVM_VERSION=17
```

### GraalVM Native Image
```
kp image create inclusion-native --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/inclusion-native --env BP_JVM_VERSION=17 --env BP_NATIVE_IMAGE=true
```

## Running the application on Knative
### Without optimizations
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

### GraalVM Native Image
```
kn service create inclusion-native --image $REGISTRY_HOST/inclusion-native
kubectl logs -l app=inclusion-native-00001 -c user-container | grep "Started InclusionApplication"
# Started InclusionApplication in 0.79 seconds (process running for 0.797)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe inclusion-native -o url)
kubectl top pods -l app=inclusion-native-00001 --containers
# POD                                                  NAME             CPU(cores)   MEMORY(bytes)
# inclusion-native-00001-deployment-58f9c764f4-d8sdz   user-container   1m           105Mi
```

### Project CraC
```
envsubst < crac/kservice.yaml | kubectl apply -f -
kubectl logs -l app=inclusion-crac-00001 -c user-container | grep "Started InclusionApplication"
# Started InclusionApplication in 0.79 seconds (process running for 0.797)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe inclusion-crac -o url)
kubectl top pods -l app=inclusion-crac-00001 --containers
# POD                                                NAME             CPU(cores)   MEMORY(bytes)
# inclusion-crac-00001-deployment-58f9c764f4-d8sdz   user-container   1m           105Mi
```
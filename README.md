
## Container image building

```
export REGISTRY_HOST=harbor.main.emea.end2end.link/going-serverless
```

### Without optimizations
```
# Remove "org.graalvm.buildtools.native" plugin in build.gradle before running the command, otherwise a native image will be build
./gradlew bootBuildImage --imageName=$REGISTRY_HOST/hello-world --publishImage
```

### GraalVM Native Image
```
./gradlew bootBuildImage --imageName=$REGISTRY_HOST/hello-world --publishImage
```

### Project CraC

```
docker build . -t $REGISTRY_HOST/hello-world-crac:checkpointer --file crac/Dockerfile
docker run -d --cap-add CHECKPOINT_RESTORE --cap-add SYS_PTRACE --rm --name hello-world-crac-checkpointer $REGISTRY_HOST/hello-world-crac:checkpointer
# Wait until checkpoint creation succeeded: docker logs $(docker ps -qf "name=hello-world-crac-checkpointer") -f
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=hello-world-crac-checkpointer") $REGISTRY_HOST/hello-world-crac
docker kill $(docker ps -qf "name=hello-world-crac-checkpointer")
# Test: docker run -d --cap-add CHECKPOINT_RESTORE --cap-add SYS_ADMIN --rm -p 8080:8080 --name hello-world-crac-checkpoint $REGISTRY_HOST/hello-world-crac
docker push $REGISTRY_HOST/hello-world-crac
```

### CDS
```
docker build . -t $REGISTRY_HOST/hello-world-cds --file cds/Dockerfile
docker push $REGISTRY_HOST/hello-world-cds
```


## Container image building with kpack

### Without optimizations
```
kp image create hello-world --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/hello-world --env BP_JVM_VERSION=17
```

### GraalVM Native Image
```
kp image create hello-world-native --git https://github.com/timosalm/going-serverless --tag $REGISTRY_HOST/hello-world-native --env BP_JVM_VERSION=17 --env BP_NATIVE_IMAGE=true
```

## Running the application on Knative
### Without optimizations
```
kn service create hello-world --image $REGISTRY_HOST/hello-world
kubectl logs -l app=hello-world-00001 -c user-container | grep "Started HelloWorldApplication"
# Started HelloWorldApplication in 4.558 seconds (process running for 5.214)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe hello-world -o url)
kubectl top pods -l app=hello-world-00001 --containers
# POD                                            NAME             CPU(cores)   MEMORY(bytes)
# hello-world-00001-deployment-cf846cc5b-bcdr7   user-container   3m           182Mi
```

### GraalVM Native Image
```
kn service create hello-world-native --image $REGISTRY_HOST/hello-world-native
kubectl logs -l app=hello-world-native-00001 -c user-container | grep "Started HelloWorldApplication"
# Started HelloWorldApplication in 0.238 seconds (process running for 0.247)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe hello-world-native -o url)
kubectl top pods -l app=hello-world-native-00001 --containers
# POD                                                  NAME             CPU(cores)   MEMORY(bytes)
# hello-world-native-00001-deployment-5959fc77fd-pbfxv   user-container   1m           40Mi
```

### Project CraC
```
envsubst < crac/kservice.yaml | kubectl apply -f -
kubectl logs -l app=hello-world-crac-00001 -c user-container | grep "Spring-managed lifecycle restart completed"
# Spring-managed lifecycle restart completed (restored JVM running for 276 ms)
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe hello-world-crac -o url)
kubectl top pods -l app=hello-world-crac-00001 --containers
# POD                                                  NAME             CPU(cores)   MEMORY(bytes)
# hello-world-crac-00001-deployment-5d48647675-c7qs4   user-container   2m           38Mi
```
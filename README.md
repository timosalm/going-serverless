# Going Serverless With Spring’s Support for GraalVM, Project CraC & Class Data Sharing (CDS)

[Session recording](https://www.youtube.com/watch?v=ZQ1Dr1v363Y)

**Update:** Support for extracting an uber JAR to a CDS friendly layout was [added in Spring Boot 3.3.0](https://docs.spring.io/spring-boot/reference/deployment/efficient.html#deployment.efficient.cds). The demo code is updated.

Special thanks to [Sébastien Deleuze](https://github.com/sdeleuze/), who is not only the lead for the topic in the Spring team but also wrote two great blog posts on it: [GraalVM, Project CRaC](https://spring.io/blog/2023/10/16/runtime-efficiency-with-spring
), [CDS](https://spring.io/blog/2023/12/04/cds-with-spring-framework-6-1).

## Container image building

*Hint: If you want to skip the container image building, you can use my images by running `export REGISTRY_HOST=harbor.main.emea.end2end.link/going-serverless`, and jump tp the "[Running the application on Knative](#running-the-application-on-knative)" section.*
```
export REGISTRY_HOST=<your-registry-hostname>(/<project>)
```

### Without optimizations
```
./gradlew bootBuildImage --imageName=$REGISTRY_HOST/hello-world --publishImage
```

### GraalVM Native Image
Uncomment "org.graalvm.buildtools.native" plugin in build.gradle before running the command.
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

### CDS
```
kn service create hello-world-cds --image $REGISTRY_HOST/hello-world-cds
kubectl logs -l app=hello-world-cds-00001 -c user-container | grep "Started HelloWorldApplication"
# Started HelloWorldApplication in 2.769 seconds
watch kubectl get pods
hey -n 1000 -c 1000 -m GET $(kn service describe hello-world-cds -o url)
kubectl top pods -l app=hello-world-cds-00001 --containers
# POD                                                 NAME             CPU(cores)   MEMORY(bytes)
# hello-world-cds-00001-deployment-5fb784757f-vtzdh   user-container   2m           10Mi
```

## Running the application on Azure Container Apps
### Without optimizations
```
az containerapp up --name hello-world --image harbor.main.emea.end2end.link/going-serverless/hello-world --ingress external --target-port 8080
az containerapp logs show -n hello-world -g DefaultResourceGroup-DEWC | grep "Started HelloWorldApplication"
watch az containerapp replica list -n hello-world -g DefaultResourceGroup-DEWC --query "[].[name,properties.runningState]"
hey -n 1000 -c 1000 -m GET $(echo "https://$(az containerapp show -n hello-world -g DefaultResourceGroup-DEWC --query properties.configuration.ingress.fqdn --only-show-errors -o yaml)")

```
### GraalVM Native Image
```
az containerapp up --name hello-world-native --image harbor.main.emea.end2end.link/going-serverless/hello-world-native --ingress external --target-port 8080
az containerapp logs show -n hello-world-native -g DefaultResourceGroup-DEWC | grep "Started HelloWorldApplication"
watch az containerapp replica list -n hello-world-native -g DefaultResourceGroup-DEWC --query "[].[name,properties.runningState]"
hey -n 1000 -c 1000 -m GET $(echo "https://$(az containerapp show -n hello-world-native -g DefaultResourceGroup-DEWC --query properties.configuration.ingress.fqdn --only-show-errors -o yaml)")

```
### Project CraC
```
az containerapp up --name hello-world-crac --image harbor.main.emea.end2end.link/going-serverless/hello-world-crac --ingress external --target-port 8080
az containerapp logs show -n hello-world-crac -g DefaultResourceGroup-DEWC | grep "Spring-managed lifecycle restart completed"
watch az containerapp replica list -n hello-world-crac -g DefaultResourceGroup-DEWC --query "[].[name,properties.runningState]"
hey -n 1000 -c 1000 -m GET $(echo "https://$(az containerapp show -n hello-world-crac -g DefaultResourceGroup-DEWC --query properties.configuration.ingress.fqdn --only-show-errors -o yaml)")
```
### CDS
```
az containerapp up --name hello-world-cds --image harbor.main.emea.end2end.link/going-serverless/hello-world-cds --ingress external --target-port 8080
az containerapp logs show -n hello-world-cds -g DefaultResourceGroup-DEWC | grep "Started HelloWorldApplication"
watch az containerapp replica list -n hello-world-cds -g DefaultResourceGroup-DEWC --query "[].[name,properties.runningState]"
hey -n 1000 -c 1000 -m GET $(echo "https://$(az containerapp show -n hello-world-cds -g DefaultResourceGroup-DEWC --query properties.configuration.ingress.fqdn --only-show-errors -o yaml)")
```

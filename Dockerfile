FROM eclipse-temurin:11-jre-alpine
# Refresh Alpine packages so OS CVEs with published fixes (e.g. gnutls) are patched before Trivy gate.
RUN apk update && apk upgrade --no-cache
VOLUME /tmp
ENV SERVER_PORT=80
EXPOSE 80
COPY target/cicd-demo-*.jar app.jar
ENTRYPOINT [ "java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar" ]

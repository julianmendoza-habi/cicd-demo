FROM eclipse-temurin:11-jre-alpine
VOLUME /tmp
ENV SERVER_PORT=80
EXPOSE 80
COPY target/cicd-demo-*.jar app.jar
ENTRYPOINT [ "java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar" ]

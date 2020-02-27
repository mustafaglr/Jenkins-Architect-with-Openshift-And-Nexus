FROM openjdk:8-jre-alpine3.7

ENV APP_PATH="/${APP_NAME}.jar" \
    SERVER_PORT=8080 \
    JVM_OPTS="-server -d64 -Xms256m -Xmx512m"
    
EXPOSE $SERVER_PORT

COPY wrapper.sh /wrapper.sh

RUN chmod 555 /wrapper.sh

COPY ./target/$APP_NAME-$APP_VERSION.jar $APP_NAME-$APP_VERSION.jar

ENTRYPOINT ["/wrapper.sh"]

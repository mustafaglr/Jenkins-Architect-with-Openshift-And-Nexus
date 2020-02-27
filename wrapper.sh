#!/bin/sh

exec  java ${JVM_OPTS} -Dserver.port=${SERVER_PORT} -jar ${APP_NAME}-${APP_VERSION}.jar

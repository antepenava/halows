FROM tomcat:9.0.115-jre25-temurin AS unpack_tomcat
WORKDIR /usr/local/tomcat
RUN mkdir /usr/local/tomcat/webapps/ROOT
COPY config/tomcat/webapps/ROOT/* /usr/local/tomcat/webapps/ROOT/
COPY config/tomcat/conf/web.xml /usr/local/tomcat/conf/
COPY config/tomcat/conf/server.xml /usr/local/tomcat/conf/
COPY config/tomcat/cert/* /usr/local/tomcat/cert/
RUN apt-get update && apt-get install -y wget unzip
RUN wget https://download.oracle.com/otn_software/java/ords/ords-24.1.1.120.1228.zip -O /opt/ords.zip
RUN unzip /opt/ords.zip -d /opt/ords && cp /opt/ords/ords.war /usr/local/tomcat/webapps

# Set the base image to Amazon Linux 2023
FROM tomcat:9.0.115-jre25-temurin

# File Author / Maintainer
LABEL maintainer="ante.penava@insife.com"
LABEL tomcat="9.0.115"
LABEL java="jre-25"
LABEL ORDS="24.1"

# ------------------------------------------------------------------------------
# Define fixed (build time) environment variables.
ENV SCRIPTS_DIR="/opt/scripts" \
    ORDS_DIR="/opt/ords" 

COPY scripts/* ${SCRIPTS_DIR}/
COPY --from=unpack_tomcat /usr/local/tomcat/ /usr/local/tomcat/
COPY --from=unpack_tomcat /opt/ords/ ${ORDS_DIR}/

RUN chmod u+x -R ${SCRIPTS_DIR}/ && chmod u+x ${ORDS_DIR}/bin/ords

EXPOSE 8443

HEALTHCHECK --interval=1m --start-period=1m \
    CMD ${SCRIPTS_DIR}/healthcheck.sh >/dev/null || exit 1

CMD exec ${SCRIPTS_DIR}/start.sh

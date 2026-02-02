#!/usr/bin/env bash
echo "******************************************************************************"
echo "Check if this is the first run." $(date)
echo "******************************************************************************"
FIRST_RUN="false"
if [ ! -f /opt/ords/CONTAINER_ALREADY_STARTED_FLAG ]; then
  echo "First run."
  FIRST_RUN="true"
  touch /opt/ords/CONTAINER_ALREADY_STARTED_FLAG
else
  echo "Not first run."
fi

echo "******************************************************************************"
echo "Handle shutdowns." $(date)
echo "docker stop --time=30 {container}" $(date)
echo "******************************************************************************"
gracefulshutdown() {
  ${CATALINA_HOME}/bin/shutdown.sh
}

trap gracefulshutdown INT
trap gracefulshutdown TERM
trap gracefulshutdown KILL


$ORDS_DIR/bin/ords --config $ORDS_DIR/config config set jdbc.InitialLimit 50 && \
$ORDS_DIR/bin/ords --config $ORDS_DIR/config config set jdbc.MaxLimit 500

if [ "$FIRST_RUN" = "true" ]; then
  echo "******************************************************************************"
  echo "Configure ORDS. Safe to run on DB with existing config." $(date)
  echo "******************************************************************************"
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config \
    install \
    --admin-user $DB_ADMIN_USER \
    --db-hostname $DATABASE_ENDPOINT \
    --db-port 1521 \
    --db-sid $DB_SID \
    --feature-db-api true \
    --feature-rest-enabled-sql true \
    --feature-sdw true \
    --proxy-user \
    --password-stdin <<EOF
$TEMP_DB_PWD
$TEMP_ORDS_PWD
EOF
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config set plsql.gateway.mode proxied
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config set security.forceHTTPS false
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config set security.verifySSL true
  #$ORDS_DIR/bin/ords --config $ORDS_DIR/config config set security.requestValidationFunction true
  #$ORDS_DIR/bin/ords --config $ORDS_DIR/config config set security.validationFunctionType true
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config set security.externalSessionTrustedOrigins "https://login.microsoftonline.com, https://localhost:8443"
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config delete security.requestValidationFunction
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config set misc.defaultPage apex
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config war ${CATALINA_HOME}/webapps/ords.war
  $ORDS_DIR/bin/ords --config $ORDS_DIR/config config user add --password-stdin APIUSER "RESTful Services" <<EOF
$TEMP_APIUSER_PWD
EOF

fi

echo "******************************************************************************"
echo "Start Tomcat." $(date)
echo "******************************************************************************"
${CATALINA_HOME}/bin/startup.sh

echo "******************************************************************************"
echo "Tail the catalina.out file as a background process" $(date)
echo "and wait on the process so script never ends." $(date)
echo "******************************************************************************"
tail -f ${CATALINA_HOME}/logs/catalina.out &
bgPID=$!
wait "$bgPID"

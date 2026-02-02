# HALOWS
# Run
sudo podman container run -i -t -d \
 --name halo-ws--pod halo-pod \
 -e DATABASE_ENDPOINT=halo-pod -e DB_ADMIN_USER=insiferoot \
 -e DB_SID=halo \
 -e TEMP_DB_PWD="DvanaestDuga1_" \
 -e TEMP_ORDS_PWD="DvanaestDuga1_" \
 -e TEMP_APIUSER_PWD="DvanaestDuga1_" \
278219041261.dkr.ecr.eu-west-1.amazonaws.com/halows:1.1
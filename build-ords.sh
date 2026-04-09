#!/bin/bash
TIMESTAMP=$(date +%Y%m%d-%H%M)
LOG_FILE="build_ords_${TIMESTAMP}.log"

# --- Logging (From Original) ---
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging session to: $LOG_FILE"

# --- Configuration ---
DIR="/mnt/d/Repos/DockerImages/halows"
AWS_REGION="eu-west-1"
AWS_PROFILE="InsifeCloudFormationDEV"
ECR_URL="278219041261.dkr.ecr.${AWS_REGION}.amazonaws.com"
REPO="ords-webserver"
TOMCAT_VER="9.0.115"
ORDS_VER="24.1"
TAG_PREFIX="ords${ORDS_VER}-tomcat${TOMCAT_VER}"
UNIQUE_TAG="${TAG_PREFIX}-${TIMESTAMP}"
LATEST_TAG="${TAG_PREFIX}-latest"

# Login
aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} | podman login --username AWS --password-stdin ${ECR_URL}

cd "$DIR" || { echo "Directory $DIR not found"; exit 1; }

echo "Building ORDS Webserver..."
podman build -t ${ECR_URL}/${REPO}:${UNIQUE_TAG} ${DIR}

echo "Tagging and Pushing ORDS..."
podman tag ${ECR_URL}/${REPO}:${UNIQUE_TAG} ${ECR_URL}/${REPO}:${LATEST_TAG}
podman push ${ECR_URL}/${REPO}:${UNIQUE_TAG}
podman push ${ECR_URL}/${REPO}:${LATEST_TAG}
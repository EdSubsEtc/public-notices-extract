exit_with_error() {
  echo "An error occurred. Exiting."
  cd ..
  exit 1
}

PROJECT_ID=application-services-dev
ARTIFACT_PROJECT_ID=application-services-dev
REGION=europe-west2
ARTIFACT_REGION=europe-west2 # Use a region allowed by org policy for artifacts

REPOSITORY=gcf-artifacts
ARTIFACT_REGISTRY=europe-west2.pkg.dev

IMAGE_NAME=public-notices-extract-dev
IMAGE_TAG=${ARTIFACT_REGION}-docker.pkg.dev/${ARTIFACT_PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:latest

JOB_NAME="${IMAGE_NAME}-job"

echo "Checking for Artifact Registry repository: $REPOSITORY..."
gcloud artifacts repositories describe $REPOSITORY \
    --project=$ARTIFACT_PROJECT_ID \
    --location=$ARTIFACT_REGION 

if [ $? -ne 0 ]; then
  echo "Repository not found. Creating repository: $REPOSITORY..."
  gcloud artifacts repositories create $REPOSITORY \
    --repository-format=docker \
    --location=$ARTIFACT_REGION \
    --description="Docker repository for public-notices-extract" \
    --project=$ARTIFACT_PROJECT_ID
fi


cd dist

docker build -t $IMAGE_TAG -f deploy.dockerfile .
if [ $? -ne 0 ]; then
  echo "Docker build failed"
  exit_with_error
fi

docker push $IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "Docker push failed"
  exit_with_error
fi

gcloud run jobs deploy $JOB_NAME \
  --image $IMAGE_TAG \
  --region $REGION \
  --project $PROJECT_ID
if [ $? -ne 0 ]; then
  echo "Job deployment failed"
  exit_with_error
fi

# echo "Job deployed. Executing job: $JOB_NAME"
# gcloud run jobs execute $JOB_NAME --region $REGION --wait --project $PROJECT_ID


echo "deploy.sh completed successfully"
exit 0

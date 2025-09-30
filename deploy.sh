supports_color() {
  case "$TERM" in
    xterm*|rxvt*|vt*|linux|screen*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

exit_with_error() {
  echo "An error occurred. Exiting."
  cd ..
  exit 1
}

ERROR_COLOR='\033[0;31m'
SUCCESS_COLOR='\033[0;32m'
NO_COLOR='\033[0m'

if supports_color; then
  ERROR_COLOR='\033[0;31m'
  NO_COLOR='\033[0m'
else
  ERROR_COLOR=''
  NO_COLOR=''
fi

#WEB_HOOK=default
WEB_HOOK=https://hook.eu2.make.com/3ax3qcsg3movh0rsiulxr3q14duqla7t

PROJECT_ID=application-services-prod
ARTIFACT_PROJECT_ID=application-services-prod

REGION=europe-west2
ARTIFACT_REGION=europe-west2 # Use a region allowed by org policy for artifacts

REPOSITORY=gcf-artifacts
ARTIFACT_REGISTRY=europe-west2.pkg.dev

IMAGE_NAME=public-notices-extract-dev
IMAGE_TAG=${ARTIFACT_REGION}-docker.pkg.dev/${ARTIFACT_PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:latest

JOB_NAME="${IMAGE_NAME}-job"

# NETWORK="landing-zone-dev"
# SUBNET=projects/landing-zone-prod-392a/regions/europe-west2/subnetworks/europe-west2-london-cloud-run-dev \

NETWORK=projects/landing-zone-prod-392a/global/networks/landing-zone-prod
SUBNET=projects/landing-zone-prod-392a/regions/europe-west2/subnetworks/europe-west2-london-cloud-run-prod

setup_job_identity() {
  echo "Setting up runtime identity for the Cloud Run Job..."
  JOB_SA_NAME="pne-job-runner"
  JOB_SA_EMAIL="${JOB_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

  # 1. Create a service account for the job to run as.
  gcloud iam service-accounts describe $JOB_SA_EMAIL --project=$PROJECT_ID > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Job runtime service account not found. Creating..."
    gcloud iam service-accounts create $JOB_SA_NAME \
      --display-name="Public Notices Extract Job Runner" \
      --project=$PROJECT_ID
    if [ $? -ne 0 ]; then
      echo -e "${ERROR_COLOR}Failed to create job runtime service account.${NO_COLOR}"
      exit_with_error
    fi
  else
    echo "Job runtime service account already exists."
  fi

  # 2. Grant the service account permission to access the required secret.
  echo "Granting secretaccessor.secretAccessor role to the job's service account..."
  gcloud secrets add-iam-policy-binding "public-notice-extract-db-connection" \
    --member="serviceAccount:${JOB_SA_EMAIL}" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID > /dev/null

  echo "Job runtime identity setup complete."
}


setup_scheduler_identity() {
  echo "Setting up identity for Cloud Scheduler..."
  SCHEDULER_SA_NAME="pne-scheduler-invoker"
  SCHEDULER_SA_EMAIL="${SCHEDULER_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

  # 1. Create a service account for the scheduler if it doesn't exist.
  gcloud iam service-accounts describe $SCHEDULER_SA_EMAIL --project=$PROJECT_ID > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Service account not found. Creating..."
    gcloud iam service-accounts create $SCHEDULER_SA_NAME \
      --display-name="Public Notices Extract Scheduler Invoker" \
      --project=$PROJECT_ID
    if [ $? -ne 0 ]; then
      echo -e "${ERROR_COLOR}Failed to create service account.${NO_COLOR}"
      exit_with_error
    fi
  else
    echo "Service account already exists."
  fi

  # 2. Grant the service account permission to invoke the Cloud Run job.
  echo "Granting run.invoker role to service account..."
  gcloud run jobs add-iam-policy-binding $JOB_NAME \
    --member="serviceAccount:${SCHEDULER_SA_EMAIL}" \
    --role="roles/run.invoker" \
    --region=$REGION \
    --project=$PROJECT_ID > /dev/null # Suppress verbose output

  echo "Scheduler identity setup complete."
}


set_web_hook() {
  echo "Setting up web hook..."

  if [ "$WEB_HOOK" = "default" ]; then

    gcloud run jobs update $JOB_NAME \
      --region $REGION \
      --project $PROJECT_ID \
      --remove-env-vars=WEB_HOOK_URL
    if [ $? -ne 0 ]; then
      echo -e "${ERROR_COLOR} Failed to remove the web hook.${NO_COLOR}"
      exit_with_error
    fi

  else

    gcloud run jobs update $JOB_NAME \
      --region $REGION \
      --project $PROJECT_ID \
      --set-env-vars=WEB_HOOK_URL=$WEB_HOOK

    if [ $? -ne 0 ]; then
      echo -e "${ERROR_COLOR} Failed to set the web hook.${NO_COLOR}"
      exit_with_error
    fi

  fi

  echo "Web hook setup complete."
}

set_schedule(){
  echo "Setting up schedule..."

  # Use the default compute service account, which is proven to work via the UI.
  # This requires getting the project number from the project ID.
  PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
  OAUTH_SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
  TARGET_URI="https://$REGION-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$PROJECT_ID/jobs/$JOB_NAME:run"

  gcloud scheduler jobs update http $JOB_NAME-schedule \
    --schedule="0 6 * * 1-6" \
    --uri="$TARGET_URI" \
    --http-method=POST \
    --oauth-service-account-email="$OAUTH_SA_EMAIL" \
    --project=$PROJECT_ID

  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR} Failed to set the schedule.${NO_COLOR}"
    exit_with_error
  fi

  echo "Schedule setup complete."
}

check_repository() {
  echo "Checking for Artifact Registry repository: $REPOSITORY..."
  gcloud artifacts repositories describe $REPOSITORY \
      --project=$ARTIFACT_PROJECT_ID \
      --location=$ARTIFACT_REGION > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}Repository $REPOSITORY not found in project $ARTIFACT_PROJECT_ID in $ARTIFACT_REGION. Please create it first.${NO_COLOR}"
    exit_with_error
  fi
  echo -e "${SUCCESS_COLOR}Repository found.${NO_COLOR}"
}

build_and_push() {
  echo "Building and pushing Docker image..."
  cd dist

  docker build --no-cache -t $IMAGE_TAG -f deploy.dockerfile .
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}Docker build failed.${NO_COLOR}"
    exit_with_error
  fi

  docker push $IMAGE_TAG
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}Docker push failed. Check authentication with 'gcloud auth configure-docker ${ARTIFACT_REGION}-docker.pkg.dev'.${NO_COLOR}"
    exit_with_error
  fi
  echo -e "${SUCCESS_COLOR}Image pushed successfully to ${IMAGE_TAG}${NO_COLOR}"
}

deploy_job() {
  echo "Deploying job: $JOB_NAME"
  JOB_SA_EMAIL="pne-job-runner@${PROJECT_ID}.iam.gserviceaccount.com"

  gcloud run jobs deploy $JOB_NAME \
    --image $IMAGE_TAG \
    --region $REGION \
    --network $NETWORK \
    --subnet  $SUBNET \
    --project $PROJECT_ID \
    --update-secrets=DB_GEMSTONE_CONNECTION_STRING=projects/479239246365/secrets/public-notice-extract-db-connection:latest \
    --service-account=$JOB_SA_EMAIL
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}Job deployment failed.${NO_COLOR}"
    exit_with_error
  fi
}

build_typescript() {
  echo "Compiling TypeScript..."
  npx tsc
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}TypeScript compilation failed.${NO_COLOR}"
    exit_with_error
  fi
}

copy_resources() {
  echo "Copying resource files..."
  ./build.sh
  if [ $? -ne 0 ]; then
    echo -e "${ERROR_COLOR}Failed to copy resource files.${NO_COLOR}"
    exit_with_error
  fi
}

main() {

  echo Comment out these steps as needed.

  # Always build the latest code and resources
  build_typescript
  copy_resources

  # Always check the repo, build the image, and push it
  check_repository
  build_and_push
  #setup_job_identity
  deploy_job

  # set_web_hook
  #setup_scheduler_identity
  #set_schedule


  # echo "Job deployed. Executing job: $JOB_NAME"
  # gcloud run jobs execute $JOB_NAME --region $REGION --wait --project $PROJECT_ID

  echo -e "${SUCCESS_COLOR}deploy.sh completed successfully.${NO_COLOR}"
  exit 0
}


# Run the main function to start the script
main

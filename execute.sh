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

PROJECT_ID=application-services-prod
REGION=europe-west2

IMAGE_NAME=public-notices-extract-dev
JOB_NAME="${IMAGE_NAME}-job"

# echo "Job deployed. Executing job: $JOB_NAME"
gcloud run jobs execute $JOB_NAME --region $REGION --wait --project $PROJECT_ID

if [ $? -ne 0 ]; then
  echo -e $ERROR_COLOR "Error: Job execution failed." $NO_COLOR
  exit 1
fi

echo -e $SUCCESS_COLOR deploy.sh completed successfully $NO_COLOR
exit 0

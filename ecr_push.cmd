@echo off
echo Step 1 - Authenticating and pushing Nginx to ECR...
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 053732977191.dkr.ecr.eu-west-2.amazonaws.com
if %errorlevel% neq 0 (
  echo ERROR: Docker login failed
  exit /b 1
)
echo Step 2 - Pulling Nginx...
docker pull nginx:latest
if %errorlevel% neq 0 (
  echo ERROR: docker pull failed
  exit /b 1
)
echo Step 3 - Tagging...
docker tag nginx:latest 053732977191.dkr.ecr.eu-west-2.amazonaws.com/ecs-fargate-repo:latest
if %errorlevel% neq 0 (
  echo ERROR: docker tag failed
  exit /b 1
)
echo Step 4 - Pushing to ECR...
docker push 053732977191.dkr.ecr.eu-west-2.amazonaws.com/ecs-fargate-repo:latest
if %errorlevel% neq 0 (
  echo ERROR: docker push failed
  exit /b 1
)
echo Done - Nginx pushed to ECR successfully.

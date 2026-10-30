#!/bin/bash

GITLAB_USER="root"
FILE="../confs/appv1.yml"
REPO="iot"
GROUP="iot"
NAMESPACE="gitlab"
GITLAB_URL="http://gitlab.local:8080/"
API="$GITLAB_URL/api/v4"
BRANCH="main"

if ! command -v jq >/dev/null; then
  if command -v apt-get >/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y jq
  else
    echo "jq is required, please install it with your package manager"
    exit 1
  fi
fi

# CREATE GITLAB PASSWORD

GITLAB_PASSWD =${ROOT_PASSWORD:-$(kubectl -n "$NS" get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d)}

echo "Trying OAuth password grant..."
TOKEN=$(curl -sS --request POST "$GITLAB_URL/oauth/token" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "username=root" \
  --data-urlencode "password=$GITLAB_PASSWORD" 2>/dev/null | jq -r '.access_token // empty' || true)

[ -n "$TOKEN" ] || { echo "Could not obtain a token"; exit 1; }

# CREATE GROUP

if [ "$(api -o /dev/null -w '%{http_code}' "$API/groups/$GROUP")" = "200" ]; then
  echo "Group '$GROUP' already exists."
else
  echo "Creating group '$GROUP'..."
  api -X POST "$API/groups" \
    --data-urlencode "name=$GROUP" --data-urlencode "path=$GROUP" \
    --data "visibility=private" >/dev/null
fi
GROUP_ID=$(api "$API/groups/$GROUP" | jq -r .id)

# CREATE REPOSITORY

PROJECT_PATH="$GROUP%2F$PROJECT"
if [ "$(api -o /dev/null -w '%{http_code}' "$API/projects/$PROJECT_PATH")" = "200" ]; then
  echo "Project '$PROJECT' already exists."
else
  echo "Creating project '$PROJECT'..."
  api -X POST "$API/projects" \
    --data-urlencode "name=$PROJECT" --data "namespace_id=$GROUP_ID" \
    --data "default_branch=$BRANCH" >/dev/null
fi

# PUSH THE FILE

NAME=$(basename "$FILE")
ENC_NAME=$(jq -rn --arg n "$NAME" '$n|@uri')
URL="$API/projects/$PROJECT_PATH/repository/files/$ENC_NAME"

CODE=$(api -o /dev/null -w '%{http_code}' -X POST "$URL" \
  --data "branch=$BRANCH" --data "commit_message=Add $NAME" \
  --data-urlencode "content@$FILE")

if [ "$CODE" = "400" ]; then
  CODE=$(api -o /dev/null -w '%{http_code}' -X PUT "$URL" \
    --data "branch=$BRANCH" --data "commit_message=Update $NAME" \
    --data-urlencode "content@$FILE")
fi

[ "$CODE" = "201" ] || [ "$CODE" = "200" ] || { echo "Push failed (HTTP $CODE)"; exit 1; }

echo "Done: $GITLAB_URL/$GROUP/$PROJECT"
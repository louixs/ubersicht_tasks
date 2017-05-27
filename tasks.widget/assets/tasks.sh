#!/bin/bash

# -- For debugging
function runDebugLogger(){
  if [ ! -e debugLogger.sh ]; then
    cd assets
    source debugLogger.sh
  else
    source debugLogger.sh    
  fi
   # Debug function to trace all scripts run below it
  activate_debug_logger
}

# Uncomment the below to enalbe the debugger
#runDebugLogger

function exitIfFail(){
  #https://sanctum.geek.nz/arabesque/testing-exit-values-bash/
  if $1; then
    :
  else
  echo "Hmm... Seems some important pieces are missing. Please follow the instruction specified above and re-run this file as ./tasks.sh after taking necessary action"
    exit 1
  fi
}

function varExists(){
  # check if the variable exists or not
  if [ "$1" ]; then
     echo 1 # var exists
  else
     echo 0 # var does not exist
  fi
}

function runOauth (){
  if [ ! -e oauth.sh ]; then
    cd assets/
    exitIfFail ./oauth.sh
  else
    exitIfFail ./oauth.sh
  fi
}

runOauth

function readCredVar(){ #rename as this is confusing this applies to extracting all values in a file after a colon :
  #$1 = file name 
  #$2 = var name e.g. CLIENT_ID
  local credVar=$(sed -e 1b "$1" | grep "$2" | sed 's/.*://' | sed 's/"//' | sed '$s/"/ /g' | xargs)
  echo "$credVar"
}

readonly PARENT_DIR=${PWD%/*}
readonly three_DIR_UP=${PWD%/*/*/*}
readonly COFFEE_FILE_NAME=$(ls ../ | grep .coffee)
readonly COFFEE_FILE="$PARENT_DIR"/"$COFFEE_FILE_NAME"
readonly GOOGLE_APP=$( readCredVar "$COFFEE_FILE" GOOGLE_APP )
readonly CONFIG_FILE="$three_DIR_UP"/google_oauth_"$GOOGLE_APP".config

# Set global immutable variables
readonly whereAwk=$(which awk)
readonly whereCat=$(which cat)
readonly whereNetstat=$(which netstat)
readonly foundPaths="${whereCat///cat}:${whereAwk///awk}:${whereNetstat///netstat}"
export PATH="$foundPaths" &&

readonly TOKEN_FILE=token.db
readonly ACCESS_TOKEN=$(cat "$TOKEN_FILE" | grep access_token | awk '{print $2}' | tr -d \",)
readonly TASK_LISTS="https://www.googleapis.com/tasks/v1/users/@me/lists"
readonly TASK_COUNT=$(sed -e 1b "$COFFEE_FILE" | grep TASK_COUNT | sed 's/.*://' | sed 's/"//' | sed '$s/"/ /g' | xargs)

# get task list id
# need a better way to get id and store it elsewhere automatically in the future
readonly TASK_LIST_ID_FROM_CONFIG=$(sed -e 1b "$CONFIG_FILE" | grep TASK_ID | sed 's/.*://' | xargs)

# this should be changed to task names as there is no easy way to find task ids from UI
# need to add a functionality to retrie list id from list name 
# readonly TASK_LIST_ID_FROM_COFFEE=$(sed -e 1b "$COFFEE_FILE" | grep TASK_ID | sed 's/.*://' | xargs)

function tasksSetup(){    
  #google tasks api ref
  #https://developers.google.com/google-apps/tasks/v1/reference/
  INBOX="https://www.googleapis.com/tasks/v1/lists/$TASK_LIST_ID_FROM_CONFIG/tasks"
}

tasksSetup

function makeTasksUrl(){
  local list_url="$1"
  local url=https://www.googleapis.com/tasks/v1/lists/"$list_url"/tasks
  echo "$url"
}

function getTasks(){
  local url=$1
  local tasks=$(curl -sH "Authorization: Bearer $ACCESS_TOKEN" "$url")
  echo $tasks
}

function getTaskListsIDs(){  
  local ids=$(./parsej.sh taskLists.db \
                | grep .id \
                | awk '{print $2}')

  echo "$ids" > taskListsIds.db
}

function getTaskLists(){
  getTasks "$TASK_LISTS" > taskLists.db
}

function getInboxTasks(){
  getTasks "$INBOX" > tasks.db
}

function getAllTasks(){
  local id
  rm allTasks.db
  while read line; do 
    local task_url=$(makeTasksUrl "$line")
    getTasks "$task_url" >> allTasks.db 
  done < taskListsIds.db
}

function getLatestTasks(){
  local howMany=$1
  #needs refactoring
  local names=$(./parsej.sh allTasks.db | grep -B 6 .needsAction | grep ].title | awk '{$1=""; print $0}')

  local updated=$(./parsej.sh allTasks.db | grep -B 6 .needsAction | grep ].updated | awk '{$1=""; print $0}')

 # echo "$names" > names.db
  echo "$names" > names.db
  echo "$updated" > updated.db
  
  local tasks=$(paste -d ', ' updated.db /dev/null names.db | sort -nr | head -n"$howMany" | awk '{$1=""; print $0","}' | sed '$s/,//g')
  echo "$tasks"
}

# Get task lists
getTaskLists
# get task IDs
getTaskListsIDs
# get all tasks from all lists based on IDs
getAllTasks
# extract names and dates and zip
getLatestTasks "$TASK_COUNT"

# sort based on updated date
# get the last three Need actions items based on updated date


#=============================================      
function latestThreeNeedActions(){  
  ./parsej.sh tasks.db \
  | grep -B 6 needsAction \
  | grep title \
  | sed 's/.*://' \
  | head -n3 \
  | sed 's/.*/&,/' \
  | awk '{$1=""; print $0}'

  # add text at the end of each line
  # http://stackoverflow.com/questions/15978504/add-text-at-the-end-of-each-line
}

#latestThreeNeedActions

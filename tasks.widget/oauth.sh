#!/bin/bash
# Name:
# Description:
# Author:

# ====================================================================================
# ====     Obtain authorization token
# ====     OAUTH2

#//////////////
# a generict function check if a variable exists or no
function checkVarExists(){
  # check if the variable exists or not
  if [ $1 ]; then
     echo 1 # var exists
  else
     echo 0 # var does not exist
  fi
}

function timeNow(){
  #output date and time for temp file name
  date +%b"_"%d"_"%a"_"%T
}

function signalGetAccessToken(){
  # let this script know that when running through checks, it needs to get access token first since authorizatoin code was retrieved and entered
  # make a tempfile first
  > signal
  echo 1 >> signal
  SIGNAL_FILE=signal
  # write 1 to indicate a signal to get access token next time this script file runs

}

# how to make a temp file
# local tempfile=$(mktemp /tmp/temp_file_$(timeNow) || exit 1)

#=================
# prechecks
function prechecks(){

#check if auth_code exists first and create if not
if [ -s auth_code ]; then
  #echo 'auth_code file exists'
  AUTH_CODE_FILE=auth_code #file where you put in authorization code
  AUTHORIZATION_CODE=$(sed -e 1b $AUTH_CODE_FILE | grep AUTHORIZATION_CODE | sed 's/.*://' | xargs)
else
  #echo 'auth_code file missing; adding one'
  > auth_code
  echo 'AUTHORIZATION_CODE:' >> auth_code
  AUTH_CODE_FILE=auth_code #file where you put in authorization code
  #AUTHORIZATION_CODE=$(sed -e 1b $AUTH_CODE_FILE | grep AUTHORIZATION_CODE | sed 's/.*://' | xargs)
fi
  
#==== create token file if it's missing; else assign a variable
if [ -s $TOKEN_FILE ]; then
  #echo 'token file exists'
  TOKEN_FILE=token
  else
  #echo 'token file missing; adding one'
  > token
  TOKEN_FILE=token
fi
#====

#==== same check for refresh token
if [ -s $R_TOKEN_FILE ]; then
  #echo 'refresh token file eixists'
  R_TOKEN_FILE=r_token
else
  #echo 'refresh token file missing; adding one'
  > r_token
  R_TOKEN_FILE=r_token
fi
#====

SIGNAL_FILE=signal

#ACCESS_TOKEN=$(cat $TOKEN_FILE | grep access_token | awk '{print $2}' | tr -d \",)

####======================================
#### config
#### put your own client id and secret
CLIENT_ID=1005264025856-2j53hi79cguh169fdk3ih8i70t2jue7k.apps.googleusercontent.com
CLIENT_SECRET=M6I5wAvFtayYeecpVHcAJ0Qv
#REDIRECT_URI="http://localhost/8080"
REDIRECT_URI=urn:ietf:wg:oauth:2.0:oob

#scopes
#https://developers.google.com/identity/protocols/googlescopes
SCOPE=https://www.googleapis.com/auth/tasks.readonly

# Only the first time you authorise your app, you need to open a web browser and allow access 
# once redirected, get the authorization token
AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&scope=$SCOPE&access_type=offline" 

#echo 'pre checks and config ends'
}
#====
# prechecks ends

#====== run prechecks
prechecks

#=====

# making temp file
# tempfile = `mktemp /temp/temp_file.XXXXXX || exit 1`
# do some stuff
# remove tempfile once work is done
# rm $tempfile
#=======================================

# ***Need to re-write using case statement

# case
# condition 1 )
# do somestuff
# ;;
# condition 2 )
# some other stuff
# ;;
# esac

# ====

# ==============================
# Func. 1 - check if authorization code exists
# If exists, go to next action
# If it doesn't exists it will prompt you to get one and fill it in to a relevant file

#====
function checkAuthCode(){
if  ([ -s $AUTH_CODE_FILE ] && [ $AUTHORIZATION_CODE ]); then
  #echo "authorization code exists"
  #echo "proceeding to next action..."
  : #this is a trick to avoid error when nothing should happen in a flow
else
  
  # Authorization code should be needed only once first
  # once it is retrived and a valid access token is issued together with a refresh token
  # the refresh token should be used to re-new access token once it expired
  #echo "Authorization code does not exist"
  #echo "Copy the code from the browser and paste into the code file"
  signalGetAccessToken
  open $AUTH_URL
  
fi
}

# and run it
checkAuthCode
# ===============================

function checkSignal(){
  if [ -s $SIGNAL_FILE ]; then
    signal_var=$(cat $SIGNAL_FILE)
  fi
}

function getToken(){
  #assign signal_var only if $SIGNAL_FILE exists
  checkSignal
  
  if ([ -s $SIGNAL_FILE ] && [ "$signal_var" -eq 1 ]); then
      # if the signal says 1 then get token first
      #get token into the file and assign variables accordingly
      curl -sd "code=$AUTHORIZATION_CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=$REDIRECT_URI&grant_type=authorization_code&access_type=offline" https://www.googleapis.com/oauth2/v4/token > $TOKEN_FILE

      local new_access_token=$(cat $TOKEN_FILE | grep access_token | awk '{print $2}' | tr -d \",)
      local new_refresh_token=$(cat $TOKEN_FILE | grep refresh_token | awk '{print $2}' | tr -d \",)

      local refresh_token_exists=$(checkVarExists $new_refresh_token)

      if [ "$refresh_token_exists" -eq 1 ]; then
       #check if the newly retrieved token actually exists to make sure 
       
      #write refresh token to the r_token file
        echo "refresh_token:$new_refresh_token" > $R_TOKEN_FILE
      #assign varialbes
        ACCESS_TOKEN=$new_access_token
        REFRESH_TOKEN=$(sed -e 1b $R_TOKEN_FILE | grep refresh_token | sed 's/.*://' | xargs)
      else
      #if token varibles are empty, then need a new authorization code and get them
        echo "Copy the code from the browser and paste it right after AUTHORIZATION_CODE: in the auth_code file"
        signalGetAccessToken
        sleep 5
        open $AUTH_URL
      fi    

    #removing temp signal file
    rm $SIGNAL_FILE
  
  else
    : #do nothing, if you don't add this you get error
      #echo "proceed to next action"
  fi
}

getToken

# then check if refresh token exists
# if refresh token is there, check if access key is expired or not
# if access key is expired, use refresh token to get a new access key

# if for some reason, access key is empty or not valid after using refresh key
# get a new authoriation code and get a new access key and refresh token


#=================================================
# OBSOLETE WARNING
# might not need this
function checkAuthCodeValidity(){
  #param1 token file name to be passed as a param
  local token_file=$1

## getting token but this also returns error if authorization code is invalid
    
# this returns 0 if it contains error (true) and 1 otherwise (false)
  validity=$(grep -q error $token_file && echo $?)

  if [[ "$validity" -eq 0 ]]; then
     echo "authorization code not valid; need a new one"
     echo "Copy the code from the browser and paste after AUTHORIZATION_CODE: in the auth_code file"
     echo "once the code is pasted in , re-run this script"
     #echo "validity: $validity"
     #whenever the open authorization url is triggered, leave a signal for this script to remember to use the retrieved authorization code to get access token
     signalGetAccessToken
     #sleep 5
     open $AUTH_URL
     #http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs
     # using this command to exit the script to prevent from running further until a valid authorization code is in place
     exit 1
     
  elif [ "$validity" -eq 1 ]; then
    #
      curl -sd "code=$AUTHORIZATION_CODE&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=$REDIRECT_URI&grant_type=authorization_code&access_type=offline" https://www.googleapis.com/oauth2/v4/token > $token_file
 
        #echo "authorization code is still valid"      
  fi
}
#=========================================================

#===================================================
#=== check access token
# description: check if access token exists and get one if missing
function tokenExists(){
  #assigning token variables to use for checks
  ACCESS_TOKEN=$(cat $TOKEN_FILE | grep access_token | awk '{print $2}' | tr -d \",)
  REFRESH_TOKEN=$(sed -e 1b $R_TOKEN_FILE | grep refresh_token | sed 's/.*://' | xargs)
 
  if ([ -s $TOKEN_FILE ] && [ $ACCESS_TOKEN ]); then
    #echo "access token exists"
    #echo "proceeding to next action.."
    #go to the next check
    : #do nothing
  else
    #echo "Access token missing; taking actions"        
    # if refresh token exists, use refresh token to get access token
    refresh_token_exists=$(checkVarExists $REFRESH_TOKEN)
    
    if [ "$refresh_token_exists" -eq 1 ]; then
       local new_token=$(curl -sd "refresh_token=$REFRESH_TOKEN&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&grant_type=refresh_token" https://www.googleapis.com/oauth2/v4/token) > $TOKEN_FILE
      #re-assign access_token to the updated one
        
       local new_access_token=$(cat $TOKEN_FILE | grep access_token | awk '{print $2}' | tr -d \",)
       local new_refresh_token=$(cat $TOKEN_FILE | grep refresh_token | awk '{print $2}' | tr -d \",)

       # check if the new access token exists to see if the valid authorization code was used
       # if the new access token is empty, need to get a new authorization and then get a new access token
       local token_exists=$(checkVarExists $new_access_token)

       if [ "$token_exists" -eq 1 ]; then
         #echo "access token was successfully retrieved"
         #save refresh_token to file
         echo "refresh_token:$new_refresh_token" > r_token

         #assign token
         ACCESS_TOKEN=$new_access_token
         REFRESH_TOKEN=$(sed -e 1b $R_TOKEN_FILE | grep refresh_token | sed 's/.*://' | xargs)
    
         #echo "New access token"
         #echo $new_access_token
         #echo "refresh token from r_token file"
         #echo $REFRESH_TOKEN
         
       else
         #echo "access token is still missing"
         #echo "authorization code needs renewal"
         #echo "get a new athorization code and paste it into the auth_code file and rerun this script"
         #leaving signal for this script remember to use authorization code to get access token
         signalGetAccessToken
         sleep 5         
         open $AUTH_URL
         exit 1 
       fi
    else
      #if refresh token is also missing, then get a new token
      #for than you'd need to get a new authorizaiton code anyways
      #echo "authorization code needs renewal"
      #echo "get a new athorization code and paste it into the auth_code file and rerun this script"
      signalGetAccessToken
      sleep 5
      open $AUTH_URL
      exit 1
    fi
  fi
}
#================== access token check ends
# run it
tokenExists
#===================================================

function checkTokenStatus(){
    #echo "access token exists; checking status"
    #echo $ACCESS_TOKEN
    # first, check if it is expired
    local status=$(curl -sL "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$ACCESS_TOKEN" | grep "expires_in")
    # this returns some values like 3600 if it's still valid
    # if not it returns nothing

#============================================================
#============================================================
    # check that the access token is not expired...    
    # once passed this test, finally do some cool stuff
    if [ "$status" ] ; then
      #echo "access key still valid"
      #echo "all good, pre-checks done"
      #echo "ready to proceed for some fun"
      exit 1
      #all good
      
#============================================================      
#============================================================      
    else
    #====== if the acess token is expired, get the new access key using the refresh token
      #echo "damn... access token token expired"
      #echo "using refresh token to re-new access token"      
      #echo "refresh token: $REFRESH_TOKEN"
      refresh_token_exists=$(checkVarExists $REFRESH_TOKEN)

      if [ "$refresh_token_exists" -eq 1 ]; then
      
        curl -sd "refresh_token=$REFRESH_TOKEN&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&grant_type=refresh_token" https://www.googleapis.com/oauth2/v4/token > $TOKEN_FILE
      #re-assign access_token to the updated one

        ACCESS_TOKEN=$(cat $TOKEN_FILE | grep access_token | awk '{print $2}' | tr -d \",)
        #echo "new access token $ACCESS_TOKEN"
        #echo "access token re-newed"
        #echo "ready for some fun"

      else
        #echo "refresh token seems to be missing"
        #echo "shouldn't ever have to run this but just in case access token is there but not refresh token"       
        #echo "the following function will re-check the status of token and retrieve a new one accordingly"
        tokenExists
      fi
        
    fi
}

# and run
checkTokenStatus

# wrapping stuff in function to avoid execution while editing
#### ===== prececks done for oauth2


#

#============================================

# ================================================================
#### Misc.


#======================================================================================
# =============== Resources
#
# japanese guide
# the best guide so far especially for the explanation about how to check if access token is epxired
#http://qiita.com/shin1ogawa/items/49a076f62e5f17f18fe5


#http://stackoverflow.com/questions/37107847/how-to-get-google-oauth-2-0-access-token-directly-using-curl-without-using-goo

# invalid_grant error
# see the second answer 
#http://stackoverflow.com/questions/10576386/invalid-grant-trying-to-get-oauth-token-from-google
#http://stackoverflow.com/questions/10576386/invalid-grant-trying-to-get-oauth-token-from-google
#https://medium.com/timekit/google-oauth-invalid-grant-nightmare-and-how-to-fix-it-9f4efaf1da35#.em9nwfpsy

# invalid client error
# http://stackoverflow.com/questions/17166848/invalid-client-in-google-oauth2 

#getting access token without opening browser 
#http://stackoverflow.com/questions/28390718/not-able-to-fetch-google-oauth-2-0-access-token

#get redirected url value
#http://unix.stackexchange.com/questions/45325/get-urls-redirect-target-with-curl

# For extracting strig after a certain character
# http://stackoverflow.com/questions/18397698/how-to-cut-a-string-after-a-specific-character-in-unix

# Todo
# toggle between different mode
# latest x tasks based on updated date - done
# tasks from certain list based on list names

# Name: Google Tasks for Übersicht using oauth2
# Description: Display 5 latest google tasks
# Author: Ryuei Sasaki
# Github: https://github.com/louixs/

# Dependencies. Best to leave them alone.
_ = require('./assets/lib/underscore.js');

GOOGLE_APP:"tasks"

command: """
  if [ ! -d assets ]; then
    cd "$PWD"/tasks.widget
    "$PWD"/assets/run.sh
  else
    assets/run.sh
  fi
"""

#==== Google API Credentials ====
# Fill in your Google API cleint id and client secret
# Save this file and a browser should launch asking you to allow widget to access google calendar
# Once you allow, you will be presented with your Authorization code. Please fill it in and save the file.
# Your calendar events should now show. If not try refreshing Übersicht.
# If you don't have your client id and/or client secret, please follow the steps in the Setup section in README.md.

CLIENT_ID:""
CLIENT_SECRET:""
AUTHORIZATION_CODE:""

# Enter the number of tasks you want to display
TASK_COUNT:"3"
TASKS_TITLE: "-- To do --"

refreshFrequency: "30m" #30 min.
#Other permitted formats: '2 days', '1d', '10h', '2.5 hrs', '2h', '1m', or '5s'

render: (output) -> """
  <div class="container"></div>
"""

update: (output,domEl)->
  # @run """
  # if [ ! -e getTasks.sh ]; then
  #   "$PWD/tasks.widget/getTasks.sh"
  # else
  #   "$PWD/getTasks.sh"
  # fi
  # """, (err, output)->
  titleToAdd= @TASKS_TITLE
  
  # Clear DOM upon every update to avoid duplicated display
  $(domEl).find(".container").empty()
  
  show=(item)->
    console.log(item)

  tasksArr=output.split(",")
  cleanArr=(arr)-> _.map(arr, (item)-> item.trim())
  cleanedTasksArr=cleanArr(tasksArr)
  
  makeHTMLTitle=(title)->
    return titleToAdd="<div class=title>#{title}</div>"

  addArrToDom = (title,arr)->
    titleToAdd=makeHTMLTitle(title)
    $(domEl).find(".container").append(titleToAdd)        
    for element,index in arr
      itemToAdd="<div class=item> • #{arr[index]}</div>" 
      $(domEl).find(".container").append(itemToAdd)

  addArrToDomFilterZero=(title, arr)->
    arrSize=_.size(arr)
    if arrSize is 0
      addToDom(title, "No task")
    else
      addArrToDom(title, arr)

  makeDomClassP=(text)->
    "<div class=p>#{text}</p>"

  addTasksToDom=()->
    addArrToDomFilterZero(titleToAdd, cleanedTasksArr)
    
  addTasksToDom()  
    
# the CSS style for this widget, written using Stylus
# (http://learnboost.github.io/stylus/)
style: """
  //-webkit-backdrop-filter: blur(20px)
  @font-face
    font-family: 'hack'
    src: url('assets/lib/hack.ttf')
  font-family: hack, Andale Mono, Melno, Monaco, Courier, Helvetica Neue, Osaka
  color:  #df740c //#6fc3df
  font-family: hack
  font-weight: 100
  font-size: 11px
  top: 35%
  left: 2%
  line-height: 1.5
  //margin-left: -40px
  //padding: 120px 20px 20px

  .title
    color: #ffe64d //#6fc3df 
    text-shadow: 0 0 1px rgba(#000, 0.5)  
"""

command: """
  if [ ! -e getTasks.sh ]; then
    "$PWD/tasks.widget/getTasks.sh"
  else
    "$PWD/getTasks.sh"
  fi
"""

# the refresh frequency in milliseconds
# 1200000 mil sec = 20 min.
refreshFrequency: 1200000

# render gets called after the shell command has executed. The command's output
# is passed in as a string. Whatever it returns will get rendered as HTML.
render: (output) -> """
  <div id="divider">----Tasks----</div>
  <div id="item1"></div>
  <div id="item2"></div>
  <div id="item3"></div>
"""

update: (output,domEl)->
  # @run """
  # if [ ! -e getTasks.sh ]; then
  #   "$PWD/tasks.widget/getTasks.sh"
  # else
  #   "$PWD/getTasks.sh"
  # fi
  # """, (err, output)->
  console.log(output)
  data=output.split(",")
  console.log(data[0])
  $(domEl).find("#item#{i+1}").text(data[i]) for i in [0..2]
  #console.log("item#{i+1}") for i in [0..2]
    
    
# the CSS style for this widget, written using Stylus
# (http://learnboost.github.io/stylus/)
style: """
  //-webkit-backdrop-filter: blur(20px)
  color: #7eFFFF
  font-family: hack
  font-weight: 100
  font-size: 11px
  top: 23%
  left: 2%
  line-height: 1.5
  //margin-left: -40px
  //padding: 120px 20px 20px
  
  p
    text-shadow: 0 0 1px rgba(#000, 0.5)
"""

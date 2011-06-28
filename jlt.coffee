#
# jlt examples:
#
# multiple keys
#  $('#template1').jlt({key: value, key2: value2}).appendTo('#holder')
#
# chained attributes, eg. %span{:jtext => user.job.title}
#  $('#template2').jlt({user: user_object, project: project_object}).appendTo('#holder')
#  
# directly access object attributes, .project{:jid => 'project_{{id}}'}
#  $('#template3').jlt(project_object).appendTo('#holder')
#
# an array of objects
# $('#template3').jlt([project_object1, project_object2]).appendTo('#holder')
#
# multiple templates at once
# $('.templates').jlt(object).appendTo('#holder');
# $e = $('.templates').jlt(object)
#


$ = jQuery

jcalc = (vars, string) ->
  embedded = string.match(/{{([^{]+)}}/g)
  unless embedded
    jcall vars, string
  else
    result = new String(string)
    i = 0
    length = embedded.length
    
    while i < length
      command = embedded[i].match(/{{(.+)}}/)[1]
      xresult = jcall(vars, command)
      result = result.replace(embedded[i], xresult)
      i++
    result

jcall = (vars, command) ->
  result = null
  return vars  if command == "self"
  segments = command.split(/\./)
  first = segments.shift()
  if typeof vars[first] == "function"
    result = vars[first]()
  else
    result = vars[first]
  while (result) and (next = segments.shift())
    if typeof result[next] == "function"
      result = result[next]()
    else
      result = result[next]
  result

jQuery.fn.downP = ->
  el = this[0] and this[0].firstChild
  while el and el.nodeType != 1
    el = el.nextSibling
  $ el

jQuery.fn.jlt = (source_data) ->
  data_array = (if $.isArray(source_data) then source_data else [ source_data or {} ])
  $newset = jQuery("<div/>")
  @each ->
    $template = $(this)

    for vars in data_array
      $clone = $template.clone()
      
      # process these structure changing directives first
      while ($e = $clone.find("[jif],[jnif],[jeach]").first())[0]
        # if
        if $e.attr("jif")
          if jcalc(vars, $e.attr("jif"))
            $e.removeAttr "jif"
          else
            $e.remove()
            continue
        # not if
        if $e.attr("jnif")
          if jcalc(vars, $e.attr("jnif"))
            $e.remove()
            continue
          else
            $e.removeAttr "jnif"
        # for each
        # neseted jlt (foreach template only uses first child, like jlt)
        if $e.attr("jeach")
          collection = $e.attr("jeach")
          $e.removeAttr "jeach"
          $e.replaceWith $e.jlt(jcalc(vars, collection))

      # now process these content changing directives
      
      $clone.find("[jtext]").each(->
        $e = $(this)
        $e.text jcalc(vars, $e.attr("jtext"))
      ).removeAttr "jtext"

      $clone.find("[jhtml]").each(->
        $e = $(this)
        $e.append jcalc(vars, $e.attr("jhtml"))
      ).removeAttr "jhtml"

      for attr_i in [ "jid", "jhref", "jaction", "jsrc" ]
        $clone.find("[" + attr_i + "]").each(->
          $e = $(this)
          $e.attr attr_i.replace("j", ""), jcalc(vars, $e.attr(attr_i))
        ).removeAttr attr_i

      $clone.find("[jclass]").each(->
        $e = $(this)
        $e.addClass jcalc(vars, $e.attr("jclass"))
      ).removeAttr "jclass"

      $clone.find("[jclass2]").each(->
        $e = $(this)
        $e.addClass jcalc(vars, $e.attr("jclass2"))
      ).removeAttr "jclass2"

      # e.g. :jdata => 'employee'  ->  .data('employee', employee)
      $clone.find("[jdata]").each(->
        $e = $(this)
        $e.data $e.attr("jdata"), jcalc(vars, $e.attr("jdata"))
      ).removeAttr "jdata"

      # e.g. <div jattr=data-user_id.user.id> -> <div data-user_id="2">
      for attr_i in [ "jattr", "jattr2", "jattr3" ]
        $clone.find("[" + attr_i + "]").each(->
          $e = $(this)
          segments = $e.attr(attr_i).split(/\./)
          attr = segments.shift()
          $e.attr attr, jcalc(vars, segments.join("."))
        ).removeAttr attr_i

      # deliberately run val last as it may depend on other attrs
      # being set first (e.g. for input[type=range] )
      $clone.find("[jval]").each(->
        $e = $(this)
        $e.val jcalc(vars, $e.attr("jval"))
      ).removeAttr "jval"

      $newset.append $clone.children()
  
  $newset.children()


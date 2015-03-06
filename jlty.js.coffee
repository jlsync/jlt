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

@jcalc = (vars, string) ->
  embedded = string.match(/{{([^{]+)}}/g)
  unless embedded
    chain_call vars, string
  else
    result = new String(string)
    for em in embedded
      command = em.match(/{{(.+)}}/)[1]
      xresult = chain_call(vars, command)
      result = result.replace(em, xresult)
    result


chain_call = (vars, command) ->
  result = null
  return vars if command == "self"
  segments = command.split(/\./)
  first = segments.shift()
  if first is 'V'   # short circut hack for Rotaville global V
    result = window.V
  else
    result = single_call(vars, first) ? single_call(window, first)
  while result? and (next = segments.shift())
    result = single_call(result, next)
  result

single_call = (object, command) ->
  match_data = command.match(/(.*)\((.*)\)/)
  if match_data?
    object[match_data[1]].apply(object, match_data[2].split(/,/))
  else if typeof object[command] == "function"
    object[command]()
  else
    object[command]

# access the templates with
# tc[dom_id] or tc.dom_id
# e.g. tc.dom_id.jlt({})

class Jltbase
  constructor: (@vars = {}) ->
    @kids = []

  do_subs: ($holder, subvars) ->

    # process these structure changing directives first
    while ($e = $holder.find("[jif],[jnif],[jblank],[jeach],[jeachenv],[jeachinc],[jeachincenv]").first()).length
      # if
      if (jif = $e.attr("jif"))
        segments = jif.split(/\+/)
        t = true
        (t &&= jcalc(subvars, s)) for s in segments
        if t
          $e.removeAttr "jif"
        else
          $e.remove()
          continue
      # not if
      if (nif = $e.attr("jnif"))
        if jcalc(subvars, nif)
          $e.remove()
          continue
        else
          $e.removeAttr "jnif"
      # if blank - like rails .blank?
      if (jblank = $e.attr("jblank"))
        # backticks for native js == ( and not coffeescripts === )
        if ( `jcalc(subvars, jblank) == false`  )
          $e.removeAttr "jblank"
        else
          $e.remove()
          continue
      # for each
      # neseted jlt (foreach template only uses first child, like jlt)
      if (collection = $e.attr("jeach"))
        $new_html = $('<div/>')
        for vs in jcalc(subvars, collection)
          $new_html.append( @do_subs( $e.clone() , vs) )
        $e.replaceWith $new_html.children()
      # for each with env
      # neseted jlt (foreach template only uses first child, like jlt)
      if (key_collection = $e.attr("jeachenv"))
        segments = key_collection.split(/\./)
        key = segments.shift()
        collection = segments.join('.')
        $new_html = $('<div/>')
        for vs in jcalc(subvars, collection)
          ivars = _.extend({}, subvars)
          ivars[key] = vs
          $new_html.append( @do_subs( $e.clone() , ivars) )
        $e.replaceWith $new_html.children()
      # for each (inc)luding root tag
      if (collection = $e.attr("jeachinc"))
        $t = $('<div/>').append($e.clone().removeAttr("jeachinc"))
        $new_html = $('<div/>')
        for vs in jcalc(subvars, collection)
          $new_html.append( @do_subs( $t.clone() , vs) )
        $e.replaceWith $new_html.children()
      # for each (inc)luding root tag with env
      if (key_collection = $e.attr("jeachincenv"))
        segments = key_collection.split(/\./)
        key = segments.shift()
        collection = segments.join('.')
        $t = $('<div/>').append($e.clone().removeAttr("jeachincenv"))
        $new_html = $('<div/>')
        for vs in jcalc(subvars, collection)
          ivars = _.extend({}, subvars)
          ivars[key] = vs
          $new_html.append( @do_subs( $t.clone() , ivars ) )
        $e.replaceWith $new_html.children()


    $holder.find("[jtext]").each(->
      $e = $(this)
      $e.text jcalc(subvars, $e.attr("jtext")) ? ""
    ).removeAttr "jtext"

    $holder.find("[jhtml]").each(->
      $e = $(this)
      $e.append jcalc(subvars, $e.attr("jhtml"))
    ).removeAttr "jhtml"

    for attr_i in [ "jid", "jhref", "jaction", "jsrc" ]
      $holder.find("[" + attr_i + "]").each(->
        $e = $(this)
        $e.attr attr_i.replace("j", ""), jcalc(subvars, $e.attr(attr_i))
      ).removeAttr attr_i

    for attr_i in [ "jclass", "jclass2", "jclass3" ]
      $holder.find("[#{attr_i}]").each(->
        $e = $(this)
        $e.addClass jcalc(subvars, $e.attr(attr_i))
      ).removeAttr attr_i

    # e.g. :jdata => 'employee'  ->  .data('employee', employee)
    $holder.find("[jdata]").each(->
      $e = $(this)
      $e.data $e.attr("jdata"), jcalc(subvars, $e.attr("jdata"))
    ).removeAttr "jdata"

    # e.g. <div jattr=data-user_id.user.id> -> <div data-user_id="2">
    for attr_i in [ "jattr", "jattr2", "jattr3", "jattr4" ]
      $holder.find("[" + attr_i + "]").each(->
        $e = $(this)
        segments = $e.attr(attr_i).split(/\./)
        attr = segments.shift()
        $e.attr attr, jcalc(subvars, segments.join("."))
      ).removeAttr attr_i

    # deliberately run val last as it may depend on other attrs
    # being set first (e.g. for input[type=range] )
    $holder.find("[jval]").each(->
      $e = $(this)
      $e.val jcalc(subvars, $e.attr("jval"))
    ).removeAttr "jval"

    instance = @
    # now process sub chunks
    $holder.find("div.jchunk").each ->
      $e = $(this)
      jchunk = $e.attr("jchunk")
      kid = new ctc[jchunk](subvars)
      instance.kids.push kid
      $e.replaceWith(kid.render())

    return $holder.children()

  render: (custom_vars = null) ->
    custom_vars ||= @vars
    if $.isArray(custom_vars)
      $new_html = $('<div/>')
      for vs in custom_vars
        $new_html.append( @do_subs( @$template.clone() , vs) )
      return @$html = $new_html.children()
    else
      return @$html = @do_subs(@$template.clone(), custom_vars)

  destroy: ->
    @$html?.remove()
    @$html = null
    k.destroy() for k in @kids
    @kids = null
    @vars = null
auto_class_counter = 0
$jholder = $('<div class="jholder"/>')

class Jltif extends Jltbase
  render: ->
    t = true
    (t &&= jcalc(@vars, s)) for s in @segments
    if t
      super()
    else
      @$html = $jholder.clone()

new_if_class = (html, jif) ->
  $template = $('<div/>').append(html)
  $template = extract_sub_templates($template)
  class extends Jltif
    $template: $template
    segments: jif.split(/\+/)

class Jltnif extends Jltbase
  render: ->
    if jcalc(@vars, @jnif)
      @$html = $jholder.clone()
    else
      super()

new_nif_class = (html, jnif) ->
  $template = $('<div/>').append(html)
  $template = extract_sub_templates($template)
  class extends Jltnif
    $template: $template
    jnif: jnif

class Jltblank extends Jltbase
  render: ->
    # backticks for native js == ( and not coffeescripts === )
    if ( `jcalc(this.vars, this.jblank) == false`  )
      super()
    else
      @$html = $jholder.clone()

new_blank_class = (html, jblank) ->
  $template = $('<div/>').append(html)
  $template = extract_sub_templates($template)
  class extends Jltblank
    $template: $template
    jblank: jblank

class Jlteach extends Jltbase
  render: ->
    results = jcalc(@vars, @collection)
    $r = super(results)


new_each_class = (html, collection) ->
  $template = $('<div/>').append(html)
  $template = extract_sub_templates($template)
  class extends Jlteach
    $template: $template
    collection: collection

extract_sub_templates = ($holder) ->
  while ($e = $holder.find("[lif],[lnif],[lblank],[leach],[leachinc]").first()).length
    if (lif = $e.attr("lif")) # L(ive)IF
      $e.removeAttr "lif"
      nc = new_if_class( $e.clone() , lif )
    else if (lnif = $e.attr("lnif"))
      $e.removeAttr "lnif"
      nc = new_nif_class( $e.clone() , lnif )
    else if (lblank = $e.attr("lblank"))
      $e.removeAttr "lblank"
      nc = new_blank_class( $e.clone(), lblank )
    else if (collection = $e.attr("leach"))
      $e.removeAttr "leach"
      nc = new_each_class( $e.clone().children(), collection )
    else if (collection = $e.attr("leachinc"))
      $e.removeAttr "leachinc"
      nc = new_each_class( $e.clone(), collection )
    else
      console?.log "SHOULD REALLY BE HERE"

    cname = "_auto_#{auto_class_counter += 1}"
    ctc[cname] = nc
    $e.replaceWith "<div class=\"jchunk\" jchunk=\"#{cname}\"/>"

  return $holder


newclass = (html) ->
  $template = $('<div/>').append(html)
  $template = extract_sub_templates($template)
  class extends Jltbase
    $template: $template


window.tc = {}  # (t)emplate_(c)ache
window.ctc = {}  # (c)lass(t)emplate_(c)ache

$(document).ready ->
  $("#templates").children().each ->
    $this = $(this)
    tc[$this.attr("id")] = $this
    ctc[$this.attr("id")] = newclass($this.children())

  $("#templates").remove()

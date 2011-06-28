/* DO NOT MODIFY. This file was compiled Tue, 28 Jun 2011 10:12:16 GMT from
 * /Users/jason/work/fun/app/scripts/jlt.coffee
 */

(function() {
  var $, jcalc, jcall;
  $ = jQuery;
  jcalc = function(vars, string) {
    var command, embedded, i, length, result, xresult;
    embedded = string.match(/{{([^{]+)}}/g);
    if (!embedded) {
      return jcall(vars, string);
    } else {
      result = new String(string);
      i = 0;
      length = embedded.length;
      while (i < length) {
        command = embedded[i].match(/{{(.+)}}/)[1];
        xresult = jcall(vars, command);
        result = result.replace(embedded[i], xresult);
        i++;
      }
      return result;
    }
  };
  jcall = function(vars, command) {
    var first, next, result, segments;
    result = null;
    if (command === "self") {
      return vars;
    }
    segments = command.split(/\./);
    first = segments.shift();
    if (typeof vars[first] === "function") {
      result = vars[first]();
    } else {
      result = vars[first];
    }
    while (result && (next = segments.shift())) {
      if (typeof result[next] === "function") {
        result = result[next]();
      } else {
        result = result[next];
      }
    }
    return result;
  };
  jQuery.fn.downP = function() {
    var el;
    el = this[0] && this[0].firstChild;
    while (el && el.nodeType !== 1) {
      el = el.nextSibling;
    }
    return $(el);
  };
  jQuery.fn.jlt = function(source_data) {
    var $newset, data_array;
    data_array = ($.isArray(source_data) ? source_data : [source_data || {}]);
    $newset = jQuery("<div/>");
    this.each(function() {
      var $clone, $e, $template, attr_i, collection, vars, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _results;
      $template = $(this);
      _results = [];
      for (_i = 0, _len = data_array.length; _i < _len; _i++) {
        vars = data_array[_i];
        $clone = $template.clone();
        while (($e = $clone.find("[jif],[jnif],[jeach]").first())[0]) {
          if ($e.attr("jif")) {
            if (jcalc(vars, $e.attr("jif"))) {
              $e.removeAttr("jif");
            } else {
              $e.remove();
              continue;
            }
          }
          if ($e.attr("jnif")) {
            if (jcalc(vars, $e.attr("jnif"))) {
              $e.remove();
              continue;
            } else {
              $e.removeAttr("jnif");
            }
          }
          if ($e.attr("jeach")) {
            collection = $e.attr("jeach");
            $e.removeAttr("jeach");
            $e.replaceWith($e.jlt(jcalc(vars, collection)));
          }
        }
        $clone.find("[jtext]").each(function() {
          $e = $(this);
          return $e.text(jcalc(vars, $e.attr("jtext")));
        }).removeAttr("jtext");
        $clone.find("[jhtml]").each(function() {
          $e = $(this);
          return $e.append(jcalc(vars, $e.attr("jhtml")));
        }).removeAttr("jhtml");
        _ref = ["jid", "jhref", "jaction", "jsrc"];
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          attr_i = _ref[_j];
          $clone.find("[" + attr_i + "]").each(function() {
            $e = $(this);
            return $e.attr(attr_i.replace("j", ""), jcalc(vars, $e.attr(attr_i)));
          }).removeAttr(attr_i);
        }
        $clone.find("[jclass]").each(function() {
          $e = $(this);
          return $e.addClass(jcalc(vars, $e.attr("jclass")));
        }).removeAttr("jclass");
        $clone.find("[jclass2]").each(function() {
          $e = $(this);
          return $e.addClass(jcalc(vars, $e.attr("jclass2")));
        }).removeAttr("jclass2");
        $clone.find("[jdata]").each(function() {
          $e = $(this);
          return $e.data($e.attr("jdata"), jcalc(vars, $e.attr("jdata")));
        }).removeAttr("jdata");
        _ref2 = ["jattr", "jattr2", "jattr3"];
        for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
          attr_i = _ref2[_k];
          $clone.find("[" + attr_i + "]").each(function() {
            var attr, segments;
            $e = $(this);
            segments = $e.attr(attr_i).split(/\./);
            attr = segments.shift();
            return $e.attr(attr, jcalc(vars, segments.join(".")));
          }).removeAttr(attr_i);
        }
        $clone.find("[jval]").each(function() {
          $e = $(this);
          return $e.val(jcalc(vars, $e.attr("jval")));
        }).removeAttr("jval");
        _results.push($newset.append($clone.children()));
      }
      return _results;
    });
    return $newset.children();
  };
}).call(this);

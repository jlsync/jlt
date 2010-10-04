/*
* jlt examples:
*
* multiple keys
*  $('#template1').jlt({key: value, key2: value2}).appendTo('#holder')
*
* chained attributes, eg. %span{:jtext => user.job.title}
*  $('#template2').jlt({user: user_object, project: project_object}).appendTo('#holder')
*  
* directly access object attributes, .project{:jid => 'project_{{id}}'}
*  $('#template3').jlt(project_object).appendTo('#holder')
*
* an array of objects
* $('#template3').jlt([project_object1, project_object2]).appendTo('#holder')
*
* multiple templates at once
* $('.templates').jlt(object).appendTo('#holder');
* $e = $('.templates').jlt(object)
*
*/

(function($){
  jQuery.fn.jlt = function(source_data) {
    /*
    var settings = {
      'location'         : 'top',
      'background-color' : 'blue'
    };
    if ( options ) { 
      $.extend( settings, options );
    }
    */

    data_array =  $.isArray(source_data) ? source_data : [ source_data ]
    var vars;  // todo: clean up ugly closure global var
    var newset = [];

    this.each(function() {
      var $template = $(this);


      $.each(data_array, function(index) {
        vars = this;
        var $clone = $template.clone();


        var $e;
        // process these structure changing directives first
        while ( ( $e = $clone.find('[jif],[jnif],[jeach]').first() )[0] ) {

          // if
          if ($e.attr('jif')) {
            if ( ! call($e.attr('jif'))) {
              $e.remove();
              continue;
            } else {
              $e.removeAttr('jif');
            }
          }

          // not if
          if ($e.attr('jnif')) {
            if ( call($e.attr('jnif'))) {
              $e.remove();
              continue;
            } else {
              $e.removeAttr('jnif');
            }
          }

          // for each
          if ($e.attr('jeach')) {
            var collection = $e.attr('jeach');
            $e.removeAttr('jeach');
            $e.replaceWith( $e.jlt(call(collection)) );
          }

        };


        // now process these content changing directives
        $clone.find('[jtext]').each(function(){
          var $e = $(this);
          $e.text(call($e.attr('jtext')));
        }).removeAttr('jtext');

        $clone.find('[jhtml]').each(function(){
          var $e = $(this);
          $e.append(call($e.attr('jhtml')));
        }).removeAttr('jhtml');

        $clone.find('[jval]').each(function(){
          var $e = $(this);
          $e.val(call($e.attr('jval')));
        }).removeAttr('jval');

        $clone.find('[jid]').each(function(){
          var $e = $(this);
          $e.attr('id',call($e.attr('jid')));
        }).removeAttr('jid');

        $clone.find('[jhref]').each(function(){
          var $e = $(this);
          $e.attr('href',call($e.attr('jhref')));
        }).removeAttr('jhref');

        $clone.find('[jaction]').each(function(){
          var $e = $(this);
          $e.attr('action',call($e.attr('jaction')));
        }).removeAttr('jaction');

        $clone.find('[jsrc]').each(function(){
          var $e = $(this);
          $e.attr('src',call($e.attr('jsrc')));
        }).removeAttr('jsrc');

        $clone.find('[jclass]').each(function(){
          var $e = $(this);
          $e.addClass(call($e.attr('jclass')));
        }).removeAttr('jclass');

        $clone.find('[jclass2]').each(function(){
          var $e = $(this);
          $e.addClass(call($e.attr('jclass2')));
        }).removeAttr('jclass2');

        // e.g. :jdata => 'employee'  ->  .data('employee', employee)
        $clone.find('[jdata]').each(function(){
          var $e = $(this);
          $e.data($e.attr('jdata'),call($e.attr('jdata')));
        }).removeAttr('jdata');

        // e.g. <div jattr=data-user_id.user.id> -> <div data-user_id="2">
        $clone.find('[jattr]').each(function(){
          var $e = $(this);
          var segments = $e.attr('jattr').split(/\./);
          var attr = segments.shift();
          $e.attr(attr, call(segments.join('.')));
        }).removeAttr('jattr');

        $clone.children().each(function(){
          newset.push(this);
        })
      });
    });

    return $(newset);

    function call(string) {
      var result = null;
      var command, embedded;


      command = (embedded = string.match(/{{(.+)}}/) ) ? embedded[1] : string;

      // todo: should I just be using eval( ) here instead?
      
      var segments = command.split(/\./);
      var first = segments.shift();
      if ( typeof vars[first] === 'function' ) {
        result = vars[first]()
      } else {
        result = vars[first]
      }
      while ((result) && (next = segments.shift())){
        if ( typeof result[next] === 'function' ) {
          result = result[next]()
        } else {
          result = result[next]
        }
      }

      return (embedded) ? string.replace(/{{.+}}/,result) : result ;
    }

  };

})(jQuery);


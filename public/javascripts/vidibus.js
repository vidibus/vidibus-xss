var vidibus = {};
(function($) {
  
  /**
   * Assign global cross-site request forgery protection variables.
   * To use vidibus.csrf, simply append it to your options object:
   *   jQuery.extend(yourSettings, vidibus.csrf.data)
   */
  vidibus.csrf = {
    param: $('meta[name=csrf-param]').attr('content'),
    token: $('meta[name=csrf-token]').attr('content'),
    
    data: function() {
      obj = {};
      if(this.param && this.token) {
        obj[this.param] = this.token;
      }
      return obj;
    }
  };
  
  if(vidibus.csrf.param && vidibus.csrf.token) {
    vidibus.csrf.data[vidibus.csrf.param] = encodeURIComponent(vidibus.csrf.token);
  }
}(jQuery));

/**
 * Implement ajax handler.
 * This is the default handler provided in rails.js with some extensions.
 */
(function($) {
  $.fn.extend({

    /**
     * Handles execution of remote calls firing overridable events along the way.
     */
    callAjax: function(url, method, data) {
      var el = this,
        meth = method || el.attr('method') || el.attr('data-method') || 'GET',
        dataType = el.attr('data-type')  || 'script';
      if (!url) {url = el.attr('action') || el.attr('href') || el.attr('data-url');}
      if (url === undefined) {
        throw "No URL specified for remote call (action or href must be present).";
      } else {
        if (el.triggerAndReturn('ajax:before')) {
          data = data || el.is('form') ? el.serializeArray() : {};
          if (meth === 'delete') {
            data._method = meth;
            meth = 'POST';
          }
          $.extend(data, vidibus.csrf.data());
          $.ajax({
            url: url,
            data: data,
            dataType: dataType,
            type: meth.toUpperCase(),
            beforeSend: function(xhr) {
              el.trigger('ajax:loading', xhr);
            },
            success: function(data, status, xhr) {
              el.trigger('ajax:success', [data, status, xhr]);
            },
            complete: function(xhr) {
              el.trigger('ajax:complete', xhr);
            },
            error: function(xhr, status, error) {
              el.trigger('ajax:failure', [xhr, status, error]);
            }
          });
        }
        el.trigger('ajax:after');
      }
    }
  });
}(jQuery));

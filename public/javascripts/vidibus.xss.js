// TODO: Support cross-domain AJAX requests in IE:
// if ($.browser.msie && window.XDomainRequest) {
//     // Use Microsoft XDR
//     var xdr = new XDomainRequest();
//     xdr.open('get', url);
//     xdr.onload = function() {
//         // XDomainRequest doesn't provide responseXml, so if you need it:
//         var dom = new ActiveXObject('Microsoft.XMLDOM');
//         dom.async = false;
//         dom.loadXML(xdr.responseText);
//     };
//     xdr.send();
// } else {
//     $.ajax({...});
// }


vidibus.xss = {
  initialized: {},      // holds true for every scope that has been initialized
  fileExtension: 'xss', // use 'xss' as file extension
  loadedUrls: {},       // store urls currently loaded in each scope

  /**
   * Detects scope of script block to be executed. 
   * Must be called from embedding page.
   */
  detectScope: function() {
    document.write('<div id="scopeDetector"></div>');
    var $detector = $("#scopeDetector");
    var $scope = $detector.parent();
    $detector.remove();
    return $scope;
  },
  
  /**
   * Usage:
   *   vidibus.xss.embed('<div>Some HTML</div>', $('#scope'), 'http://host.url/');
   */
  embed: function(html, $scope, host) {
    html = this.transformPaths(html, $scope); // Transform local paths before embedding html into page!
    $scope.html(html);
    this.setUrls($scope);
    this.setActions($scope);
  },
  
  /**
   * Calls given path for given scope. If a third parameter is set to true,
   * the location will be loaded, even if it is currently loaded.
   * 
   * Usage:
   *   vidibus.xss.get('path', $('#scope') [, true]);
   * 
   * If no host is provided, host of scope will be used.
   */
  get: function(path, $scope, reload) {
    // Escape query parts
    path = path.replace("?", "%3F").replace("&", "%26").replace("=", "%3D");

    var scopeId = $scope[0].id,
        params = scopeId+'='+this.getPath(path),
        keepCurrentLocation = this.initialized[scopeId] ? 0 : 1,
        location = $.param.fragment(String(document.location), params, keepCurrentLocation),
        reloadScope = {};
    
    this.initialized[scopeId] = true;
    window.location.href = location; // write history
    reloadScope[scopeId] = reload;
    this.loadUrl(location, reloadScope);
  },
  
  /**
   * Redirect to given path while forcing reloading.
   */
  redirect: function(path, $scope) {
    this.get(path, $scope, true)
  },
  
  /**
   * Handles callback action.
   *
   * Requires data.status:
   *   redirect, TODO: ok, error
   *
   * Accepts actions depending on status:
   *   (redirect) to: Performs redirect to location.
   */
  callback: function(data, $scope) {    
    if (data.status == 'redirect') {
      this.redirect(data.to, $scope);
    }
  },
  
  /**
   * Sets host for given scope.
   */
  setHost: function(host, $scope) {
    $scope.attr('data-host', host);
  },
  
  /**
   * Returns host for given scope.
   */
  getHost: function($scope) {
    return $scope.attr('data-host');
  },
  
  /**
   * Turns given path into an absolute url.
   */
  getUrl: function(path, host) {
    if (path.match(/https?:\/\//)) { return path }
    return host + path;
  },
  
  /**
   * Returns relative path from url.
   */
  getPath: function(url) {
    return url.replace(/https?:\/\/[^\/]+/,'')
  },
  
  /**
   * Rewrites links to absolute urls.
   */
  setUrls: function($scope) {
    var host = this.getHost($scope);

    // Rewrite links
    $('a[href]:not([href^=http])', $scope).each(function(e) {
      var href = $(this).attr('href');
      $(this).attr('href', vidibus.xss.getUrl(href, host));
    });
    
    // Rewrite forms
    $('form[action]', $scope).each(function(e) {
      var action = $(this).attr('action');
      $(this).attr('href', vidibus.xss.getUrl(action, host));
    });
  },
  
  /**
   * Set xss actions for interactive elements.
   */
  setActions: function($scope) {
    var host = this.getHost($scope);
     
    // Set action for GET links
    // TODO: Allow links to be flagged as "external"
    $('a[href^='+host+']:not([data-method],[data-remote])', $scope).bind('click.xss', function(e) {
      var href = $(this).attr('href');
      vidibus.xss.get(href, $scope);
      e.preventDefault();
    });
    
    // Set action non-GET links
    // TODO: Remove bindings from links that match current host only: a[data-method][href^='+host+']:not([data-remote])
    $('a[data-method]:not([data-remote])').die('click').unbind('click'); // remove bindings
    $('a[data-method][href^='+host+']:not([data-remote])', $scope).click(function(e) {
      var $link = $(this),
          path = $link.attr('href'),
          url = vidibus.xss.buildUrl(path, $scope);
      $(this).callAjax(url);
      e.preventDefault();
    });
    
    // Set form action
    $('form[action]').die('submit').unbind('submit') // remove bindings
    $('form[action][href^='+host+']', $scope).submit(function(e) {
      var $form = $(this),
          path = $form.attr('action');
          url = vidibus.xss.buildUrl(path, $scope);
      $(this).callAjax(url);
      return false;
    });
  },
  
  /**
   * Modifies paths within given html string.
   * This method must be called before embedding html snippet into the page
   * to avoid loading errors from invalid relative paths.
   */
  transformPaths: function(html, $scope) {
    var match, url;
    while (match = html.match(/src="((?!http)[^"]+)"/)) {
      url = vidibus.xss.buildUrl(match[1], $scope);
      html = html.replace(match[0], 'src="'+url+'"')
    }
    return html;
  },
  
  /**
   * Load XSS sources from given url.
   * If url is empty, the current location will be used.
   */
  loadUrl: function(url, reload) {
    var scope, $scope, path, loaded, params = $.deparam.fragment();
    for(scope in params) {
      path = params[scope];

      // don't reload locations that have already been loaded
      loaded = this.loadedUrls[scope];
      if((!reload || !reload[scope]) && loaded && loaded == path) {
        continue;
      }

      $scope = $('#'+scope);
      if($scope[0] == undefined) {
        console.log('Scope not found: '+scope);
      } else {
        this.loadedUrls[scope] = path;
        this.loadData(path, $scope);
      }
    }
  },
  
  /**
   * Load relative path into given scope.
   * Transforms scope host and path into a XSS location.
   */
  loadData: function(path, $scope) {
    var url = this.buildUrl(path, $scope, true);
    $.ajax({
      url: url,
      data: [],
      dataType: 'script',
      type: 'GET'
    });
  },
  
  /**
   * Tranforms local paths to absolute ones.
   */
  buildUrl: function(path, $scope, uncached) {
    var parts = path.split("?");
    path = parts[0];
    params = parts[1];
    if(params) {
      params = params.split("&");
    } else {
      params = []
    }

    var host = this.getHost($scope),
      scope = $scope.attr('id'),
      url = this.getUrl(path, host)

    if (!url.match(/\.[a-z]+((\?|\#).*)?$/)) url += '.xss';
    if (url.indexOf('.xss') > -1 && params.toString().indexOf('scope='+scope) == -1) {
      params.push('scope='+scope);
    }
    
    // add cache buster
    if (uncached) {
      var d = new Date();
      params.push(d.getTime());
    }
    
    // append params
    if (params.length) {
      if (url.indexOf('?') == -1) url += '?'
      url += params.join('&');
    }

    return url;
  }
};

/**
 * Detect changes to document's location.
 * 
 */
$(function($){
  
  // Detect changes of document.location and trigger loading.
  $(window).bind('hashchange', function(e) {
    if (vidibus.loader.complete) {
      vidibus.xss.loadUrl();
    }
    return false;
  });

  // Since the event is only triggered when the hash changes, we need
  // to trigger the event now, to handle the hash the page may have
  // loaded with.
  $(window).trigger('hashchange');
});

/**
 * Implement ajax handler. 
 * This is the default handler provided in rails.js extended to accept delete method.
 */
$(function($) {
  $.fn.extend({
    
    /**
     * Handles execution of remote calls firing overridable events along the way.
     */
    callAjax: function(url) {
      var el = this,
        method = el.attr('method') || el.attr('data-method') || 'GET',
        dataType = el.attr('data-type')  || 'script';
      if (!url) url = el.attr('action') || el.attr('href');
      if (url === undefined) {
        throw "No URL specified for remote call (action or href must be present).";
      } else {
        if (el.triggerAndReturn('ajax:before')) {
          var data = el.is('form') ? el.serializeArray() : {};
          if (method == 'delete') {
            data['_method'] = method;
            method = 'POST';
          }
          $.ajax({
            url: url,
            data: data,
            dataType: dataType,
            type: method.toUpperCase(),
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
});
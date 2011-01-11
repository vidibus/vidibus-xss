// Basic loader for stylesheets and javascripts.
  
var xssLoader = {
  complete: true,       // indicates that loading has been finished
  queue: [],            // holds resources that are queued to load
  loading: undefined,   // holds resource that is currently being loaded
  preloaded: undefined, // holds resources that are included in consumer base file
  loaded: {},           // holds resources that are currently loaded
  unused: {},           // holds resources that are loaded, but not required anymore
  
  /**
   * Load resources.
   */
  load: function(resources, scope) {
    this.initStaticResources();
    this.complete = false;
    this.unused = jQuery.extend({}, this.loaded); // clone

    $(resources).each(function() {
      var resource = this,
          src = resource.src,
      
          name = xssLoader.resourceName(src);
      resource.name = name;
      resource.scopes = {}
      resource.scopes[scope] = true;
      
      // remove current file, because it is used
      delete xssLoader.unused[name];

      // skip files that have already been loaded
      if (xssLoader.loaded[name]) {
        xssLoader.loaded[name].scopes[scope] = true; // add current scope
        return; // continue
      } else if (xssLoader.preloaded[name]) {
        return; // continue
      }

      xssLoader.loaded[name] = resource;
      switch (resource.type) {
        
        // load css file directly
        case 'text/css':
          var element = document.createElement("link"); 
          element.rel = 'stylesheet'; 
          element.href = src; 
          element.media = resource.media || 'all';
          element.type = 'text/css';
          xssLoader.appendToHead(element);
          break;
          
        // push script file to loading queue
        case 'text/javascript':
          xssLoader.queue.push(resource);
          break;
          
        default: console.log('xssLoader.load: unsupported resource type: '+resource.type);
      }
    });
    
    this.loadQueue(true);
    this.unloadUnused(scope);
  },
  
  /**
   * Returns file name of resource.
   */
  resourceName: function(url) {
    return url.match(/\/([^\/\?]+)(\?.*)*$/)[1];
  },
  
  /**
   * Returns list of static resources.
   */
  initStaticResources: function() {
    if (xssLoader.preloaded === undefined) {
      xssLoader.preloaded = {};
      var $resource, src, name;
      $('script[src],link[href]',$('head')).each(function() {
        $resource = $(this);
        src = $resource.attr('src') || $resource.attr('href');
        name = xssLoader.resourceName(src);
        xssLoader.preloaded[name] = src;
      });
    }
  },
  
  /**
   * Loads resources in queue.
   */
  loadQueue: function(start) {
    
    // Reduce queue if this method is called as callback.
    if(start != true) {
      xssLoader.queue.shift();
    }
    
    
    var resource = xssLoader.queue[0];
    // return if file is currently loading
    if (resource) {
      if (resource == xssLoader.loading) {
        // console.log('CURRENTLY LOADING: '+resource.src);
        return;
      }
      xssLoader.loading = resource;
      xssLoader.loadScript(resource.src, xssLoader.loadQueue);
    } else {
      xssLoader.loading = undefined;
      xssLoader.complete = true;
    }
  },
  
  /**
   * Loads script src.
   */
  loadScript: function(src, callback) {
    var element = document.createElement("script");
    if (element.addEventListener) {
      element.addEventListener("load", callback, false);
    } else {
      // IE
      element.onreadystatechange = function() {
        if (this.readyState == 'loaded') callback.call(this);
      }
    }
    element.type = 'text/javascript';
    element.src = src;
    xssLoader.appendToHead(element);
    element = null;
  },
  
  /**
   * Detects unused resources and removes them.
   */
  unloadUnused: function(scope) {
    var name, resources = [];
    for(name in xssLoader.unused) {
      if (xssLoader.unused.hasOwnProperty(name)) {
        // Remove dependency for given scope.
        if (xssLoader.unused[name].scopes[scope]) {
          delete xssLoader.unused[name].scopes[scope];
        }

        // Unload resource if it has no dependencies left.
        if ($.isEmptyObject(xssLoader.unused[name].scopes)) {
          resources.push(xssLoader.unused[name]);
        }
      }
    }
    xssLoader.unload(resources);
    xssLoader.unused = {};
  },
  
  /**
   * Removes resources given in list.
   */
  unload: function(resources) {
    var src, data, resource;
    $(resources).each(function() {
      resource = this;
      src = resource.src;

      // console.log('REMOVE UNUSED RESOURCE: '+src);
      
      switch (resource.type) {
        case "text/css": 
          $('link[href="'+src+'"]').remove();
          break;
          
        case "text/javascript": 
          $('script[src="'+src+'"]').remove();
          break;
          
        default: console.log('xssLoader.unload: unsupported resource type: '+resource.type);
      }
      delete xssLoader.loaded[resource.name];
    });
  },
  
  /**
   * Appends given element to document head.
   */
  appendToHead: function(element) {
    document.getElementsByTagName("head")[0].appendChild(element);
  }
};

// Maintain compatibility
if (typeof vidibus != "undefined") {
  vidibus.loader = xssLoader;
}

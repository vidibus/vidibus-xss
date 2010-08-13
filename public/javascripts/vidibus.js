// if (typeof console == undefined) {
//   console = {};
// }


var vidibus = {};

// Basic loader for stylesheets and javascripts.
vidibus.loader = {
  
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
          name = vidibus.loader.resourceName(src);
      
      resource.name = name;
      resource.scopes = {}
      resource.scopes[scope] = true;
      
      // remove current file, because it is used
      delete vidibus.loader.unused[name];

      // skip files that have already been loaded
      if (vidibus.loader.loaded[name]) {
        vidibus.loader.loaded[name].scopes[scope] = true; // add current scope
        return; // continue
      } else if (vidibus.loader.preloaded[name]) {
        return; // continue
      }
      
      vidibus.loader.loaded[name] = resource;
      switch (resource.type) {
        
        // load css file directly
        case 'text/css':
          var element = document.createElement("link"); 
          element.rel = 'stylesheet'; 
          element.href = src; 
          element.media = resource.media || 'all';
          element.type = 'text/css';
          vidibus.loader.appendToHead(element);
          break;
          
        // push script file to loading queue
        case 'text/javascript':
          vidibus.loader.queue.push(resource);
          break;
          
        default: console.log('vidibus.loader.load: unsupported resource type: '+resource.type);
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
    if (vidibus.loader.preloaded == undefined) {
      vidibus.loader.preloaded = {};
      var $resource, src, name;
      $('script[src],link[href]',$('head')).each(function() {
        $resource = $(this);
        src = $resource.attr('src') || $resource.attr('href');
        name = vidibus.loader.resourceName(src);
        vidibus.loader.preloaded[name] = src;
      });
    }
  },
  
  /**
   * Loads resources in queue.
   */
  loadQueue: function(start) {
    
    // Reduce queue if this method is called as callback.
    if(start != true) {
      vidibus.loader.queue.shift();
    }
    
    var resource = vidibus.loader.queue[0];
    
    // return if file is currently loading
    if (resource) {
      if (resource == vidibus.loader.loading) {
        // console.log('CURRENTLY LOADING: '+resource.src);
        return;
      }
      vidibus.loader.loading = resource;
      vidibus.loader.loadScript(resource.src, vidibus.loader.loadQueue);
    } else {
      vidibus.loader.loading = undefined;
      vidibus.loader.complete = true;
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
    vidibus.loader.appendToHead(element);
    element = null;
  },
  
  /**
   * Detects unused resources and removes them.
   */
  unloadUnused: function(scope) {
    var name, resources = [];
    for(name in vidibus.loader.unused) {

      // Remove dependency for given scope.
      if (vidibus.loader.unused[name].scopes[scope]) {
        delete vidibus.loader.unused[name].scopes[scope];
      }
      
      // Unload resource if it has no dependencies left.
      if ($.isEmptyObject(vidibus.loader.unused[name].scopes)) {
        resources.push(vidibus.loader.unused[name]);
      }
    }
    vidibus.loader.unload(resources);
    vidibus.loader.unused = {}
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
          
        default: console.log('vidibus.loader.unload: unsupported resource type: '+resource.type);
      }
      delete vidibus.loader.loaded[resource.name];
    });
  },
  
  /**
   * Appends given element to document head.
   */
  appendToHead: function(element) {
    document.getElementsByTagName("head")[0].appendChild(element);
  }
};
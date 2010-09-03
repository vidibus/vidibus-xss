// if (typeof console == undefined) {
//   console = {};
// }


var vidibus = {};

jQuery(function ($) {
  
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
});

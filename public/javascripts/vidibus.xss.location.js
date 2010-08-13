namespace("vidibus.xss").location = {
  
};

$(function(){
  
  $(window).bind("hashchange", function(e) {
    //alert(document.location);
    
    // extract current xss location from document.location
    // check if current xss location matches new xss location (has to be stored in variable)
    
    // if it does not match, transform location into url
    // and load new url
    
  });
  
  $(window).trigger("hashchange");
});


$(function() {
  $(".pagination a").live("click", function() {
    $.setFragment({ "page" : $.queryString(this.href).page })
    $(".pagination").html("Page is loading...");
    return false;
  });
  
  $.fragmentChange(true);
  $(document).bind("fragmentChange.page", function() {
    $.getScript($.queryString(document.location.href, { "page" : $.fragment().page }));
  });
  
  if ($.fragment().page) {
    $(document).trigger("fragmentChange.page");
  }
});
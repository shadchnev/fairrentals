function showError(responseText, textStatus, xhr) {
  if (textStatus != 'success' && textStatus != 'notmodified') {
    $(this).html('<div>Sorry, an error has occurred, please check the details entered.</div>');
  }  
}

$(document).ready(function() {
  $('form').submit(function() {
    var payload = {
      postcode: $('#postcode').val(),
      beds: $('#size').val(),
      price: $('#price').val()
    }
    var regions = {
      de: '#berlin',
      fr: '#paris',
      es: '#madrid',
      it: '#rome'
    }
    $('#fair-result').html('<div><div class="spinner"></div>').load('/similar-properties', payload, showError);
    $.each(regions, function(region, id) { $(id).load('/abroad', $.extend(payload, {region: region}), showError) })
    return false;
  })
})

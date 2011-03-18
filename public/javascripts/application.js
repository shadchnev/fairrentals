function showError(element) {
  $(element).html('<div>Please specify the postcode and the price</div>');  
}

function handleError(responseText, textStatus, xhr) {
  if (textStatus != 'success' && textStatus != 'notmodified') {
    showError(this);
  }  
}

$(document).ready(function() {
  $('form').submit(function() {
    var payload = {
      postcode: $('#postcode').val(),
      beds: $('#size').val(),
      price: $('#price').val()
    }
    if (!payload.postcode || !payload.price || !payload.beds) {
      showError($('#fair-result'));
      return false;
    }
    var regions = {
      de: '#berlin',
      fr: '#paris',
      es: '#madrid',
      it: '#rome'
    }
    $('#fair-result').html('<div><div class="spinner"></div>').load('/similar-properties', payload, handleError);
    $.each(regions, function(region, id) { $(id).empty().load('/abroad', $.extend(payload, {region: region}), handleError) })
    return false;
  })
})

function showError(responseText, textStatus, xhr) {
  if (textStatus != 'success' && textStatus != 'notmodified') {
    $(this).html('<div>Sorry, an error has occurred, please check the details entered.</div>');
  }  
}

$(document).ready(function() {
  $('form').submit(function() {
    payload = {
      postcode: $('#postcode').val(),
      beds: $('#size').val(),
      price: $('#price').val()
    }
    $('#fair-result, #berlin').html('<div><img src="/images/ajax-loader.gif" /></div>')
    $('#fair-result').load('/similar-properties', payload, showError);
    $('#berlin').load('/abroad', $.extend(payload, {region: 'de'}), showError);
    return false;
  })
})

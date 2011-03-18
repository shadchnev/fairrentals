$(document).ready(function() {
  $('form').submit(function() {
    $('#fair-result').html('<div><img src="/images/ajax-loader.gif" /></div>')
    payload = {
      postcode: $('#postcode').val(),
      beds: $('#size').val(),
      price: $('#price').val()
    }
    $('#fair-result').load('/similar-properties', payload, function(responseText, textStatus, xhr) {
      if (textStatus != 'success' && textStatus != 'notmodified') {
        $(this).html('<div>Sorry, an error has occurred, please check the details entered.</div>');
      }
    });
    return false;
  })
})

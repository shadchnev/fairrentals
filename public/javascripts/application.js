$(document).ready(function() {
  $('form').submit(function() {
    payload = {
      postcode: $('#postcode').val(),
      beds: $('#size').val(),
      price: $('#price').val()
    }
    $('#fair-result').load('/similar-properties', payload);
    return false;
  })
})

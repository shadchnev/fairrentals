$(document).ready(function() {
  $('form').submit(function() {
    payload = {
      postcode: $('#postcode input').val(),
      beds: $('#size select').val(),
      price: $('#price input').val()
    }
    $('#fair-result').load('/similar-properties', payload);
    return false;
  })  
})

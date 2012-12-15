$(function() {
  $('#save').on('click', function() {
    // Get active profiles
    var profiles = {};
    $(':checked').each(function(i, el) {
      profiles[$(el).attr('id').replace('profile_', '')] = $(el).data('name');
    });

    // Get email addresses
    var emails = _.map($('#emails').val().split("\n"), function(email) {
      return email.trim();
    });

    $.ajax({
      type: 'POST',
      url: '/update_settings',
      contentType: 'application/json',
      processData: false,
      data: JSON.stringify({ profiles: profiles, emails: emails }),
      error: function() { alert('Error!') },
      success: function() { console.log('yes') }
    });

    return false;
  });
});

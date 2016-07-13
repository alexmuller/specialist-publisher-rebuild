//= require jquery
//= require select2
//= require length_counter

jQuery(function($) {
  $(".select2").select2({
    placeholder: $(this).data('placeholder')
  });

  ////
  // Make a select2 that will create new values on return as you type them
  $(".select2.free-form-list").select2({
    tags: true,
    createTag: function (params) {
      return {
        id: params.term,
        text: params.term,
        newOption: true
      }
    }
  });

  $('.js-hidden').hide();

  $('.js-update-type-major').click(function() {
    $('.js-change-note').show();
  });

  $('.js-update-type-minor').click(function() {
    $('.js-change-note').hide();
  });

  $(".js-length-counter").each(function(){
    new GOVUK.LengthCounter({$el:$(this)});
  });

  $("#preview-button").click(function(){
      $('.preview_container').removeClass('hide');
      var bodyText = $('.body-text').val();
      var attachments = $('#mydata').attr('data');
      console.log(attachments);
      $.post(
          "/preview",
          { bodyText: bodyText,
            attachments: attachments
          },
          function(data) {
              $('.govspeak').html(data);
          }
      );
      return false;
  });
});

var newIdeaTitle, newIdeaBody;

$(document).ready(function () {
  newIdeaTitle = $('.new-idea-title');
  newIdeaBody = $('.new-idea-body');

  $('.new-idea-submit').on('click', createIdea);
});

function createIdea(event) {
  event.preventDefault();

  var newIdea = getIdeaPropertiesFromForm();

  IdeaRepository.create(newIdea).then(fetchAndRenderIdeas);
}

function getIdeaPropertiesFromForm() {
  return {
    title: newIdeaTitle.val(),
    body: newIdeaBody.val()
  };
}

$(document).ready(function () {
  fetchAndRenderIdeas();
});

var IdeaRepository = {
  all: function () {
    return $.getJSON('/api/v1/ideas');
  },
  create: function (idea) {
    return $.post('/api/v1/ideas', {idea: idea});
  }
};

var ideaTemplate = _.template(
  '<div class="idea">' +
    '<h2 class="idea-title"><%= title %></h2>' +
    '<p class="idea-body"><%= body %></p>' +
    '<p class="idea-quality"><%= quality %></p>' +
    '<div class="idea-qualities idea-buttons">' +
      '<button class="idea-promote">Promote</button>' +
      '<button class="idea-demote">Demote</button>' +
    '</div>' +
    '<div class="idea-actions idea-buttons">' +
      '<button class="idea-edit">Edit</button>' +
      '<button class="idea-delete">Delete</button>' +
    '</div>' +
  '</div>'
);

function renderIdea(idea) {
  return $(ideaTemplate(idea));
}

function renderIdeas(ideas) {
  return ideas.map(renderIdea);
}

function renderIdeasToTarger(ideas, target) {
  $(target).html(ideas);
  return ideas;
}

function fetchAndRenderIdeas() {
  return IdeaRepository.all()
                       .then(renderIdeas)
                       .then(function (ideas) {
                          renderIdeasToTarger(ideas, '.ideas');
                       });
}

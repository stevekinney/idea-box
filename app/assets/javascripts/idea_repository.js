$(document).ready(function () {
  IdeaRepository.all()
                .then(renderIdeas)
                .then(function (ideas) {
                  appendIdeasToTarget(ideas, '.ideas')
                });
});

IdeaRepository = {
  all: function () {
    return $.getJSON('/api/v1/ideas');
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
)

function renderIdea(idea) {
  return $(ideaTemplate(idea));
}

function renderIdeas(ideas) {
  return ideas.map(renderIdea);
}

function appendIdeasToTarget(ideas, target) {
  $(target).append(ideas);
  return ideas;
}

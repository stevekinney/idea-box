var ideaTemplate = _.template(
  '<div class="idea idea-<%= id %>">' +
    '<h2 class="idea-title"><%= title %></h2>' +
    '<p class="idea-body"><%= body %></p>' +
    '<p class="idea-quality"><%= quality %></p>' +
    '<div class="idea-qualities idea-buttons">' +
      '<button class="idea-promote">Promote</button>' +
      '<button class="idea-demote">Demote</button>' +
      '<button class="idea-delete">Delete</button>' +
    '</div>' +
  '</div>'
);

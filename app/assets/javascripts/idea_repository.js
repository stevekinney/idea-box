var IdeaRepository = {
  all: function () {
    return $.getJSON('/api/v1/ideas')
            .then(renderIdeas);
  },
  create: function (idea) {
    return $.post('/api/v1/ideas', {idea: idea})
            .then(renderIdea);
  }
};

var ideasContainer;

$(document).ready(function () {
  ideasContainer = $('.ideas');

  IdeaRepository.all()
                .then(prependIdeasToContainer);
});

function renderIdeas(ideas) {
  ideas.map(renderIdea);
  return ideas;
}

function renderIdea(idea) {
  idea.render = function () {
    idea.element = $(ideaTemplate(idea));
    return idea;
  };

  idea.prependTo = function (target) {
    idea.element.prependTo(target);
    return idea;
  };

  idea.delete = deleteIdea;

  idea.bindEvents = function () {
    idea.element.find('.idea-delete').on('click', function () {
      idea.delete();
    });

    return idea;
  };

  return idea.render().bindEvents();
}

function prependIdeaToContainer(idea) {
  idea.prependTo(ideasContainer);
  return idea;
}

function prependIdeasToContainer(ideas) {
  return ideas.map(prependIdeaToContainer);
}

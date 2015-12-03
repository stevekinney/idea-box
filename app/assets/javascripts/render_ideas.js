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
    this.element = $(ideaTemplate(this));
    return this;
  };

  idea.prependTo = function (target) {
    this.element.prependTo(target);
    return this;
  };

  return idea.render();
}

function prependIdeaToContainer(idea) {
  idea.prependTo(ideasContainer);
  return idea;
}

function prependIdeasToContainer(ideas) {
  return ideas.map(prependIdeaToContainer);
}

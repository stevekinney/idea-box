var ideasContainer;

$(document).ready(function () {
  ideasContainer = $('.ideas');

  IdeaRepository.all()
                .then(prependIdeasToContainer);
});

function renderIdeas(ideas) {
  return ideas.map(renderIdea);
}

function renderIdea(idea) {
  return new Idea(idea);
}

function prependIdeaToContainer(idea) {
  idea.prependTo(ideasContainer);
  return idea;
}

function prependIdeasToContainer(ideas) {
  return ideas.map(prependIdeaToContainer);
}

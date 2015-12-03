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

  idea.rerender = function () {
    idea.element.replaceWith(idea.render().bindEvents().element);
    return idea;
  };

  idea.prependTo = function (target) {
    idea.element.prependTo(target);
    return idea;
  };

  idea.toJSON = function () {
    return { idea: _.pick(this, ['title', 'body', 'quality']) }
  };

  idea.promote = promoteIdea;
  idea.demote = demoteIdea;
  idea.delete = deleteIdea;
  idea.update = updateIdea;

  idea.bindEvents = function () {
    idea.element.find('.idea-delete').on('click', function () {
      idea.delete();
    });

    idea.element.find('.idea-promote').on('click', function () {
      idea.promote().then(idea.rerender);
    });

    idea.element.find('.idea-demote').on('click', function () {
      idea.demote().then(idea.rerender);
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

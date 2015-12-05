function Idea(data) {
  this.id = data.id;
  this.title = data.title;
  this.body = data.body;
  this.quality = data.quality;

  this.render().bindEvents();
}

Idea.prototype.promote = function () {
  if (this.quality === 'plausible') { this.quality = 'genius'; }
  if (this.quality === 'swill') { this.quality = 'plausible'; }
  return this.update();
};

Idea.prototype.demote = function () {
  if (this.quality === 'plausible') { this.quality = 'swill'; }
  if (this.quality === 'genius') { this.quality = 'plausible'; }
  return this.update();
};

Idea.prototype.delete = function () {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this));
};

Idea.prototype.update = function () {
  return $.ajax({
    method: 'PUT',
    url: '/api/v1/ideas/' + this.id,
    data: this.toJSON()
  });
};

Idea.prototype.render = function () {
  this.element = $(ideaTemplate(this));
  return this;
};

Idea.prototype.rerender = function () {
  this.element.replaceWith(this.render().bindEvents().element);
  return this;
};

Idea.prototype.prependTo = function (target) {
  this.element.prependTo(target);
  return this;
};

Idea.prototype.toJSON = function () {
  return { idea: _.pick(this, ['title', 'body', 'quality']) };
};

Idea.prototype.bindEvents = function () {
  this.element.find('.idea-delete').on('click', function () {
    this.delete();
  }.bind(this));

  this.element.find('.idea-promote').on('click', function () {
    this.promote().then(this.rerender.bind(this));
  }.bind(this));

  this.element.find('.idea-demote').on('click', function () {
    this.demote().then(this.rerender.bind(this));
  }.bind(this));

  return this;
};

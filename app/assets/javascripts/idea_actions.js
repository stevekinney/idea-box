function promoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'genius'; }
  if (this.quality === 'swill') { this.quality = 'plausible'; }
  return this.update();
}

function demoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'swill'; }
  if (this.quality === 'genius') { this.quality = 'plausible'; }
  return this.update();
}

function deleteIdea() {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this));
}

function updateIdea() {
  return $.ajax({
    method: 'PUT',
    url: '/api/v1/ideas/' + this.id,
    data: this.toJSON()
  });
}

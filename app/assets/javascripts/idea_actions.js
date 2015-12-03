function deleteIdea() {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this))
}

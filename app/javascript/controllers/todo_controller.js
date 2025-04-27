import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="todos"
export default class extends Controller {
  static targets = [ "title", "form" ]

  connect() {
  }

  submitForm(event) {
    event.preventDefault()

    this.formTarget.requestSubmit();
  }

  updateTitle(event) {
    event.preventDefault()

    const newTitle = event.target.innerText;
    this.titleTarget.value = newTitle;

    this.formTarget.requestSubmit();

    event.target.blur()
  }
}

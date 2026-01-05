import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 3000 } }

  connect() {
    setTimeout(() => {
      this.element.classList.add("animate-fade-out")
      setTimeout(() => this.element.remove(), 300)
    }, this.delayValue)
  }
}

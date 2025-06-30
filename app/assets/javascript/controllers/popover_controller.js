import { Controller } from "@hotwired/stimulus"
import { Popover} from "bootstrap"

export default class extends Controller {
  connect() {
    console.log("connecting")
    new Popover(this.element)
  }
}

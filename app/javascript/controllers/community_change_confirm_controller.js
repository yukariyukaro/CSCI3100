import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["select", "password"]
    static values = { originalCommunityId: Number }

    connect() {
        this.element.addEventListener("submit", this.onSubmit)
    }

    disconnect() {
        this.element.removeEventListener("submit", this.onSubmit)
    }

    onSubmit = (event) => {
        if (!this.hasSelectTarget) return

        const selected = parseInt(this.selectTarget.value, 10)
        if (!selected || selected === this.originalCommunityIdValue) return
        if (this.hasPasswordTarget && this.passwordTarget.value.trim() === "") {
            window.alert("Current password is required to change your community.")
            event.preventDefault()
            return
        }

        const ok = window.confirm(
            "Changing your community will automatically offline all your active listings in the previous community. Listings will not move to the new community (re-list required). Continue?"
        )
        if (!ok) event.preventDefault()
    }
}


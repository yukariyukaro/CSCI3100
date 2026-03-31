import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autocomplete"
export default class extends Controller {
  static targets = [ "input", "results", "loading" ]
  static values = { url: String }

  connect() {
    this.currentFocus = -1
    this.search = this.debounce(this.search.bind(this), 300)
    
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeDropdown.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.closeDropdown.bind(this))
  }

  debounce(func, wait) {
    let timeout
    return function(...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }

  onInput() {
    this.currentFocus = -1
    const query = this.inputTarget.value.trim()
    
    if (query.length < 2) {
      this.closeDropdown()
      return
    }

    this.showLoading()
    this.search(query)
  }

  async search(query) {
    if (this.abortController) {
      this.abortController.abort()
    }
    this.abortController = new AbortController()

    try {
      const response = await fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        signal: this.abortController.signal,
        headers: {
          "Accept": "application/json"
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.renderResults(data, query)
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        console.error("Autocomplete fetch error:", error)
      }
    } finally {
      this.hideLoading()
    }
  }

  renderResults(results, query) {
    this.resultsTarget.innerHTML = ""
    
    if (results.length === 0) {
      const li = document.createElement("li")
      li.className = "autocomplete-item no-results"
      li.textContent = "未找到匹配项"
      this.resultsTarget.appendChild(li)
    } else {
      results.forEach((item, index) => {
        const li = document.createElement("li")
        li.className = "autocomplete-item"
        li.dataset.action = "click->autocomplete#selectItem"
        li.dataset.index = index
        li.dataset.value = item
        
        const regex = new RegExp(`(${query})`, 'gi')
        const highlightedText = item.replace(regex, '<b>$1</b>')
        li.innerHTML = highlightedText
        
        this.resultsTarget.appendChild(li)
      })
    }
    
    this.resultsTarget.classList.remove("hidden")
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  closeDropdown(e) {
    if (e && this.element.contains(e.target)) return
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
  }

  selectItem(e) {
    const item = e.currentTarget
    this.inputTarget.value = item.dataset.value
    this.closeDropdown()
    this.element.requestSubmit()
  }

  onKeydown(e) {
    const items = this.resultsTarget.querySelectorAll(".autocomplete-item:not(.no-results)")
    if (items.length === 0) return

    if (e.key === "ArrowDown") {
      e.preventDefault()
      this.currentFocus++
      this.addActive(items)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this.currentFocus--
      this.addActive(items)
    } else if (e.key === "Enter") {
      if (this.currentFocus > -1) {
        e.preventDefault()
        items[this.currentFocus].click()
      }
    }
  }

  addActive(items) {
    if (!items) return
    this.removeActive(items)
    if (this.currentFocus >= items.length) this.currentFocus = 0
    if (this.currentFocus < 0) this.currentFocus = (items.length - 1)
    items[this.currentFocus].classList.add("autocomplete-active")
    items[this.currentFocus].scrollIntoView({ block: "nearest" })
  }

  removeActive(items) {
    for (let i = 0; i < items.length; i++) {
      items[i].classList.remove("autocomplete-active")
    }
  }
}

# Tailwind Slider using stimulus
> [Original article from boringrails.com](https://boringrails.com/articles/tailwind-style-css-transitions-with-stimulusjs/)
---

### How to map the transitions to stimulus?
> Below it's the class lifecycle for vue.

<img src="https://boringrails.com/images/enter-leave-diagram.png" alt="The lifecycle stages for CSS transitions in Vue">

The process is straightforward: First, we animate from point A to B (enter), then we go back from B to A (leave).

In each case, we follow these steps:

- Apply a set of classes with initial styles.
- Use a set of classes throughout the process.
- Apply a set of classes with final styles.

Now, let's organize everything.

### Here is how to do the map using "el-transition"
```html
<!--
  Off-canvas menu backdrop, show/hide based on off-canvas menu state.

  Entering: "transition-opacity ease-linear duration-300"
    From: "opacity-0"
    To: "opacity-100"
  Leaving: "transition-opacity ease-linear duration-300"
    From: "opacity-100"
    To: "opacity-0"
-->

data-transition-enter="transition-opacity ease-linear duration-300"
data-transition-enter-start="opacity-0"
data-transition-enter-end="opacity-100"
data-transition-leave="transition-opacity ease-linear duration-300"
data-transition-leave-start="opacity-100"
data-transition-leave-end="opacity-0"
```

### Stimulus Controller
> You need to target other elements as well to toggle their visibility.

```js
import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition";

// Connects to data-controller="slide-over"
export default class extends Controller {
  static targets = ["container", "backdrop", "panel", "closeButton"];

  show() {
    this.containerTarget.classList.remove("hidden");
    enter(this.backdropTarget);
    enter(this.closeButtonTarget);
    enter(this.panelTarget);
  }

  hide() {
    Promise.all([
      leave(this.backdropTarget),
      leave(this.closeButtonTarget),
      leave(this.panelTarget),
    ]).then(() => {
      this.containerTarget.classList.add("hidden");
    });
  }
}
```

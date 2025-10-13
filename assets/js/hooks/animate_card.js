const AnimateCard = {
  animatedElement: null,
  animations: [],
  mounted() {
    const animations = this.el.dataset.animations;
    if (animations) {
      this.animations = JSON.parse(animations);
    }
  },

  updated() {
    this.animations.forEach((animation) => {
      const animatedElement = document.getElementById(animation.elementId);
      if (animatedElement) {
        animation.classes.forEach((cls) => {
          animatedElement.classList.remove(cls)
          // Trigger reflow to restart animation
          void animatedElement.offsetWidth;
          animatedElement.classList.add(cls)
        });
      }
    })
  }
};

export default AnimateCard;

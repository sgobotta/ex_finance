const AnimateCurrencyBanner = {
  animatedElement: null,
  animations: [],
  mounted() {
    const animations = this.el.dataset.animations;
    if (animations) {
      this.animations = JSON.parse(animations);
    }

    this.handleEvent('show_conversion_banner', () => {
      const element = document.getElementById(this.animations.elementId);
      element.classList.remove('hidden');
      element.classList.add('animate-slide-up');

      setTimeout(() => {
        element.classList.remove('animate-slide-up');
      }, 1000);
    })
  }
};

export default AnimateCurrencyBanner;

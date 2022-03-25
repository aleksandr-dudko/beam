// Licensed under the Apache License, Version 2.0 (the 'License'); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

function calcBodyWidth() {
  return window.innerWidth && document.documentElement.clientWidth ?
    Math.min(window.innerWidth, document.documentElement.clientWidth) :
    window.innerWidth ||
    document.documentElement.clientWidth ||
    document.getElementsByTagName('body')[0].clientWidth;
}

(function () {

  var CountOfSlides = {
    min: 1,
    renderedOnDesktop: 3,
  }

  var Selectors = {
    desktopSlider: '.quotes-desktop.keen-slider-JS',
    mobileSlider: '.quote-mobile.keen-slider-JS',
    oneSlide: '.keen-slider__slide',
  }
  var classVisible = 'visible';

  var tabletWidth = 1024;
  var bodyWidth = calcBodyWidth();
  var isDesktopWidth = bodyWidth >= tabletWidth;

  var currentSliderSelector = isDesktopWidth ? Selectors.desktopSlider : Selectors.mobileSlider;
  var currentSliderDOM = document.querySelector(currentSliderSelector);
  currentSliderDOM.classList.add(classVisible);

  var renderedCountOfSlides = isDesktopWidth ? CountOfSlides.renderedOnDesktop : CountOfSlides.min;
  var actualCountOfSlides = document
    .querySelector(currentSliderSelector)
    .querySelectorAll(Selectors.oneSlide)
    .length;

  var isNeedLoop = true;
  if (isDesktopWidth && actualCountOfSlides <= CountOfSlides.renderedOnDesktop) {
    isNeedLoop = false;
  }
  if (!isDesktopWidth && actualCountOfSlides === CountOfSlides.min) {
    isNeedLoop = false;
  }

  var slider = new KeenSlider(currentSliderSelector, {
    slidesPerView: renderedCountOfSlides,
    loop: isNeedLoop,
    created: function (instance) {
      if (!isNeedLoop) {
        return;
      }
      var dots_wrapper = document.getElementById("dots");
      var slides = currentSliderDOM.querySelectorAll(".keen-slider__slide");
      slides.forEach(function (t, idx) {
        var dot = document.createElement("button");
        dot.classList.add("dot");
        dots_wrapper.appendChild(dot);
        dot.addEventListener("click", function () {
          instance.moveToSlide(idx);
        });
      });
      updateClasses(instance);
    },
    slideChanged(instance) {
      updateClasses(instance);
    }
  });

  function updateClasses(instance) {
    var slide = instance.details().relativeSlide;

    var dots = document.querySelectorAll(".dot");
    dots.forEach(function (dot, idx) {
      idx === slide
        ? dot.classList.add("dot--active")
        : dot.classList.remove("dot--active");
    });
  }
}());

// ==UserScript==
// @name        unfix-all-the-toolbars
// @description Removes "position: fixed" style from elements, unfixing "toolbars" and the such.
// @namespace   https://hasanyavuz.ozderya.net
// @include     *
// @version     1
// @grant       none
// ==/UserScript==


// Based on https://stackoverflow.com/questions/13696100/greasemonkey-script-to-make-fixed-positioned-elements-static
// and https://gist.github.com/vbuaraujo/bddb3b93a0b2b7e28e1b

fixed_items = [];

function unfixAll() {
  Array.forEach(
    document.querySelectorAll("h1, h2, ul, ol, li, div, nav, header, footer"),
    function (el) {
      var style = window.getComputedStyle(el);
      if (style.position === "fixed" && style.top == "0px" &&
          !(style.display === "none" || style.visibility === "hidden"))
          /* Avoid unfixing JavaScript popups like Twitter's "confirm retweet" window */
      {
        fixed_items.push(el);
        //el.style.position = "static";
        el.style.visibility = "hidden";
        /* I tried using "absolute" in the past, but this breaks WordPress's footer.
           Using "static" breaks it too, but at least it doesn't get in the way. */
      }
    });
}

function fixBack()
{
  Array.forEach(
    fixed_items,
    function(el) {
      //el.style.position = "fixed";
      el.style.visibility = "";
    }
  )
  fixed_items = [];
}

function onScroll()
{
  if (window.scrollY > 0)
  {
    unfixAll();
  }
  else
  {
    fixBack();
  }
}

window.addEventListener("scroll", onScroll);
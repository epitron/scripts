// ==UserScript==
// @name         xhamsterdance
// @namespace    xhamsterdance
// @version      0.1
// @author       You
// @include      https://*.xhamster.com/*
// @include      https://*.xvideos.com/*
// @include      https://*.pornhub.com/*
// @grant        none
// ==/UserScript==

(function() {
  'use strict';

  var onsite = (site) => {
    if (document.location.host.indexOf(site) >= 0) {
      console.log(`* making ${site} dance...`)
      return true
    } else {
      return false
    }
  }

  var video_html = (url) => {
    return `<video loop=true autoplay=true muted=true playsinline=true><source src='${url}'></video>`
  }

  var remove_node = (e) => {
    e.parentNode.removeChild(e)
  }

  var remove_handlers = (old_e) => {
    var e = old_e.cloneNode(true)
    old_e.parentNode.replaceChild(e, old_e)
    return e
  }

  console.log("* xhamsterdance initializing...")

  if (onsite("xhamster.com")) {
    document.querySelectorAll(".video-thumb__image-container").forEach((e) => {
      e = remove_handlers(e)
      var url = e.getAttribute("data-previewvideo")
      console.log(url)
      e.innerHTML = video_html(url)
    })
  } else if (onsite("xvideos.com")) {
    document.querySelectorAll(".thumb img").forEach((e) => {
      var thumb = e.src
      var wide  = thumb.indexOf("/thumbs169") !== -1
      var ad    = e.data && (e.data("isad") === !0)

      if (!ad) {
        var url = thumb.substring(0,thumb.lastIndexOf("/")).replace(/\/thumbs(169)?(xnxx)?l*\//,"/videopreview/")+(wide?"_169.mp4":"_43.mp4")
        console.log(url)
        e.parentNode.innerHTML = video_html(url)
      } else {
        console.log("ad")
      }
    })
  } else if (onsite("pornhub.com")) {
    document.querySelectorAll("img.js-videoThumb").forEach((e) => {
      var url = e.getAttribute("data-mediabook")
      var a = e.parentNode
      a.innerHTML = video_html(url)
    })

    document.querySelectorAll(".phimage .preloadLine").forEach((e) => {
      remove_node(e)
    })
  }

})();


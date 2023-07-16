function toggleSource(id) {
  var src = $('#' + id).toggle();
  var isVisible = src.is(':visible');
  $('#l_' + id).html(isVisible ? 'hide' : 'show');
}

// document.addEventListener("turbo:load", function() {
//   if (location.hash) {
//     window.turboTargetHack ||= document.createElement("a")
// console.log("HERE1", location.hash, this)
//     turboTargetHack.href = location.hash
//     turboTargetHack.click()

//     // const a = document.createElement('a')
//     // a.href = `#${location.hash.slice(1)}`
//     // a.click()
//   }

//   // spotlight('#' + location.hash);
// });

// document.addEventListener("hashchange", function() {
// console.log("HERE2a", location.hash, this)
//   if (location.hash) {
//     window.turboTargetHack ||= document.createElement("a")
// console.log("HERE2b", location.hash, this)
//     turboTargetHack.href = location.hash
//     turboTargetHack.click()

//     // const a = document.createElement('a')
//     // a.href = `#${location.hash.slice(1)}`
//     // a.click()
//   }

//   // spotlight('#' + location.hash);
// });



// addEventListener('turbo:load', target)
// addEventListener('hashchange', target) // for same-page navigations

function target () {
console.log("HERE", location.hash)
  window.a ||= document.createElement('a')
  if (location.hash) {
    // const a = document.createElement('a')
    a.href = `#${location.hash.slice(1)}`
    a.click()
  }
}

addEventListener("turbo:click", () => console.log("click!!"))
addEventListener("turbo:load", () => console.log("load!!"))
addEventListener("turbo:visit", () => console.log("visit!!"))
addEventListener("hashchange", () => console.log("hashchange!!"))


document.addEventListener("turbo:load", function() {
  // Only initialize panel if not yet initialized
  if(!$('#panel .tree ul li').length) {
    $('#links').hide();
    var panel = new Searchdoc.Panel($('#panel'), search_data, tree);
    var s = window.location.search.match(/\?q=([^&]+)/);
    if (s) {
      s = decodeURIComponent(s[1]).replace(/\+/g, ' ');
      if (s.length > 0) {
        $('#search').val(s);
        panel.search(s, true);
      }
    }
    panel.toggle(JSON.parse($('meta[name="data-tree-keys"]').attr("content")));
  }
});

// Keep scroll position for panel
(function() {
  var scrollTop = 0;

  addEventListener("turbo:before-render", function() {
    scrollTop = $('#panel').first().scrollTop();
  })

  addEventListener("turbo:render", function() {
    $('#panel').first().scrollTop(scrollTop);
  })
})()

document.addEventListener("turbo:load", function () {
  var backToTop = $("a.back-to-top");

  backToTop.on("click", function (e) {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  });

  var toggleBackToTop = function () {
    if (window.scrollY > 300) {
      backToTop.addClass("show");
    } else {
      backToTop.removeClass("show");
    }
  }

  $(document).scroll(toggleBackToTop);
})

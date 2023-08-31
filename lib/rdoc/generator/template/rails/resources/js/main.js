import { Search } from "./search.js";

window.spotlight = function(url) {
  var hash = url.match(/#([^#]+)$/);
  if (hash) {
    var link = document.querySelector('a[name=' + hash[1] + ']');
    if(link) {
      var parent = link.parentElement;

      parent.classList.add('spotlight');

      setTimeout(function() {
        parent.classList.remove('spotlight');
      }, 1000);
    }
  }
};

document.addEventListener("turbo:load", function() {
  spotlight('#' + location.hash);
});

document.addEventListener("turbo:load", async () => {
  const searchInput = document.getElementById("search");
  const searchOutput = document.getElementById("results");
  const search = new Search(searchInput, searchOutput, (url, module, method, summary, score) =>
    `<div class="results__result" data-score="${score}">
      <a class="result__link" href="${url}">
        <code class="result__module">${module.replaceAll("::", "::<wbr>")}</code>
        <code class="result__method">${method || ""}</code>
      </a>
      <p class="result__summary description">${summary || ""}</p>
    </div>`
  );

  const query = new URL(document.location).searchParams.get("q");
  if (query) {
    search.feelingLucky(query);
  }
}, { once: true });

document.addEventListener("turbo:load", function() {
  // Only initialize panel if not yet initialized
  if(!$('#panel .tree ul li').length) {
    $('#links').hide();
    var panel = new Searchdoc.Panel($('#panel'), tree);
    panel.toggle(JSON.parse($('meta[name="data-tree-keys"]').attr("content")));
  }
});

// Keep scroll position for panel
(function() {
  var scrollTop = 0;

  addEventListener("turbo:before-render", function() {
    scrollTop = document.querySelector(".panel__tree").scrollTop
  })

  addEventListener("turbo:render", function() {
    document.querySelector(".panel__tree").scrollTop = scrollTop
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

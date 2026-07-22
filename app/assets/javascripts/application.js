// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"

import $ from "jquery"

$(document).on("turbo:load", function () {
  var btn = document.querySelector('.theme-toggle');
  if (btn) {
    var isDark = document.documentElement.classList.contains('dark-theme');
    btn.querySelector('.icon-sun').style.display = isDark ? '' : 'none';
    btn.querySelector('.icon-moon').style.display = isDark ? 'none' : '';
  }

  // Copy to clipboard (field style - click icon to copy from input)
  $("[data-copy-target]").on("click", function (e) {
    e.preventDefault();

    var $icon = $(this);
    var $target = $icon.parent().parent().find($icon.data("copy-target"));

    $target.select();
    navigator.clipboard.writeText($target.val()).then(function() {
      $icon.attr("data-tooltip", "已复制!");
      setTimeout(function () {
        $icon.attr("data-tooltip", $icon.data("origin-title") || "复制到剪贴板");
        $target.blur();
      }, 2000);
    });

    return false;
  });

  // Auto-copy when focusing the input field
  $(".js-copy-to-clipboard").find("input").on("focus", function () {
    $(this).parent().next().find("a[data-copy-target]").click();
  });

  // Copy to clipboard (icon style - click to copy text)
  $("[data-copy]").on("click", function (e) {
    e.preventDefault();

    var $icon = $(this);
    var text = $(this).data("copy");

    navigator.clipboard.writeText(text).then(function() {
      $icon.attr("data-tooltip", "已复制!");
      setTimeout(function () {
        $icon.attr("data-tooltip", $icon.data("origin-title") || "复制到剪贴板");
      }, 2000);
    });

    return false;
  });
});

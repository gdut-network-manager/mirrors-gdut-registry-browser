// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"

import $ from "jquery"

$(document).on("turbo:load", function () {
  // Delete confirmation gating
  $("#delete_confirm").on("keyup", function (e) {
    e.preventDefault();

    var field = $(this);
    var button = $("#delete-button");

    if (field.val() == field.attr("data-expected")) {
      button.removeClass("disabled");
    }
    else {
      button.addClass("disabled");
    }
  });

  // Copy to clipboard (field style - click icon to copy from input)
  $("[data-copy-target]").on("click", function (e) {
    e.preventDefault();

    var $icon = $(this);
    var $target = $icon.parent().parent().find($icon.data("copy-target"));

    $target.select();
    navigator.clipboard.writeText($target.val()).then(function() {
      // Show copied feedback via CSS tooltip
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
      // Show copied feedback via CSS tooltip
      $icon.attr("data-tooltip", "已复制!");
      setTimeout(function () {
        $icon.attr("data-tooltip", $icon.data("origin-title") || "复制到剪贴板");
      }, 2000);
    });

    return false;
  });

  // Modal open/close (for delete dialog)
  $("[data-toggle='modal']").on("click", function (e) {
    e.preventDefault();
    var target = $(this).data("target");
    $(target).addClass("active");
  });

  $("[data-dismiss='modal']").on("click", function (e) {
    e.preventDefault();
    $(this).closest(".modal-overlay").removeClass("active");
  });

  // Close modal on overlay click
  $(".modal-overlay").on("click", function (e) {
    if ($(e.target).is(".modal-overlay")) {
      $(this).removeClass("active");
    }
  });

  // Collapse toggle (replaces Bootstrap collapse)
  $("[data-collapse-target]").on("click", function (e) {
    e.preventDefault();
    var target = $($(this).data("collapse-target"));
    target.toggleClass("collapse");
    $(this).toggleClass("collapsed");
  });

  // Tab switching
  $(".nav-tab").on("click", function (e) {
    e.preventDefault();
    var tabId = $(this).attr("href") || $(this).data("tab");

    // Update active tab
    $(this).closest(".nav-tabs").find(".nav-tab").removeClass("active");
    $(this).addClass("active");

    // Show corresponding content
    $(".tab-content").removeClass("active");
    $(tabId).addClass("active");
  });
});

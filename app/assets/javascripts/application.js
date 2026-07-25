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

  // Sub tabs (Vulnerability / SBOM / History)
  $("[data-sub-tab-target]").on("click", function () {
    var target = $(this).data("sub-tab-target");
    var wrapper = $(this).closest(".sub-tabs-wrapper");

    wrapper.find(".sub-tab").removeClass("active");
    $(this).addClass("active");

    wrapper.find(".sub-tab-content").removeClass("active");
    wrapper.find("#" + target).addClass("active");
  });

  // Vulnerability group expand/collapse + default open
  $(".vuln-group-header").each(function () {
    if ($(this).data("default-open")) {
      $(this).closest(".vuln-group").addClass("open");
    }
  });

  $(".vuln-group-header").on("click", function () {
    $(this).closest(".vuln-group").toggleClass("open");
  });

  // Vulnerability item detail expand/collapse
  $(".vuln-item-main").on("click", function (e) {
    if ($(e.target).is("a") || $(e.target).closest("a").length) return;
    $(this).siblings(".vuln-item-detail").toggleClass("show");
  });

  // Vulnerability search
  $("[data-vuln-search]").on("input", function () {
    var query = $(this).val().toLowerCase().trim();
    var manifestId = $(this).data("vuln-search");
    var groupsContainer = $('[data-vuln-groups="' + manifestId + '"]');
    var noResults = $('[data-vuln-no-results="' + manifestId + '"]');
    var visibleCount = 0;

    groupsContainer.find(".vuln-item").each(function () {
      var id = ($(this).data("vuln-id") || "").toString().toLowerCase();
      var pkg = ($(this).data("vuln-package") || "").toString().toLowerCase();
      var desc = ($(this).data("vuln-desc") || "").toString().toLowerCase();

      if (query === "" || id.includes(query) || pkg.includes(query) || desc.includes(query)) {
        $(this).removeClass("hidden");
        visibleCount++;
      } else {
        $(this).addClass("hidden");
      }
    });

    groupsContainer.find(".vuln-group").each(function () {
      var groupVisible = $(this).find(".vuln-item:not(.hidden)").length;
      if (groupVisible > 0) {
        $(this).removeClass("filtered-out");
        $(this).addClass("open");
      } else {
        $(this).addClass("filtered-out");
      }
    });

    noResults.toggle(visibleCount === 0);
  });

  // SBOM search
  $("[data-sbom-search]").on("input", function () {
    var query = $(this).val().toLowerCase().trim();
    var manifestId = $(this).data("sbom-search");
    var tableWrapper = $('[data-sbom-table="' + manifestId + '"]');
    var noResults = $('[data-sbom-no-results="' + manifestId + '"]');
    var visibleCount = 0;

    tableWrapper.find(".sbom-row").each(function () {
      var pkg = ($(this).data("sbom-pkg") || "").toString();
      if (query === "" || pkg.includes(query)) {
        $(this).removeClass("hidden");
        visibleCount++;
      } else {
        $(this).addClass("hidden");
      }
    });

    noResults.toggle(visibleCount === 0);
  });
});

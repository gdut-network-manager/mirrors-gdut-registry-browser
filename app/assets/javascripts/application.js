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

  // ==========================================
  // Pagination + Filter + Search + Sort
  // ==========================================

  var PAGE_SIZE = 20;
  var vulnStates = {};
  var sbomStates = {};
  var originalRowOrders = {};

  function getVulnState(manifestId) {
    if (!vulnStates[manifestId]) {
      vulnStates[manifestId] = { page: 1, filter: "all", query: "" };
    }
    return vulnStates[manifestId];
  }

  function saveOriginalOrder(table) {
    var tableId = table.data("sortable-table");
    if (tableId !== undefined && !originalRowOrders[tableId]) {
      originalRowOrders[tableId] = table.find("tbody tr").get();
    }
  }

  function restoreOriginalOrder(table) {
    var tableId = table.data("sortable-table");
    if (originalRowOrders[tableId]) {
      var tbody = table.find("tbody");
      $.each(originalRowOrders[tableId], function (i, row) {
        tbody.append(row);
      });
    }
  }

  function applyDefaultSortIndicators(table) {
    var defaultSort = table.data("default-sort");
    if (!defaultSort) return;
    var parts = defaultSort.split(":");
    var key = parts[0];
    var dir = parts[1] || "asc";
    table.find(".sortable-th").removeClass("sorted-asc sorted-desc");
    table.find('.sortable-th[data-sort-key="' + key + '"]').addClass(dir === "asc" ? "sorted-asc" : "sorted-desc");
  }

  function initTableState(scope) {
    scope = scope || document;

    $(scope).find("[data-vuln-filter-chips]").each(function () {
      var manifestId = $(this).data("vuln-filter-chips");
      saveOriginalOrder($(scope).find('[data-sortable-table="' + manifestId + '"]'));
      vulnStates[manifestId] = { page: 1, filter: "all", query: "" };
      updateVulnView(manifestId, vulnStates[manifestId]);
    });

    $(scope).find("[data-sbom-search]").each(function () {
      var manifestId = $(this).data("sbom-search");
      saveOriginalOrder($(scope).find('[data-sortable-table="' + manifestId + '"]'));
      sbomStates[manifestId] = { page: 1, query: "" };
      updateSbomView(manifestId, 1, "");
    });
  }

  function updateVulnView(manifestId, state) {
    vulnStates[manifestId] = state;
    var tableWrapper = $('[data-vuln-table="' + manifestId + '"]');
    var pagination = $('[data-vuln-pagination="' + manifestId + '"]');
    var noResults = $('[data-vuln-no-results="' + manifestId + '"]');

    var allRows = tableWrapper.find(".vuln-row");
    var filtered = [];

    allRows.each(function () {
      var sev = $(this).data("vuln-severity") || "Unknown";
      var id = ($(this).data("vuln-id") || "").toString().toLowerCase();
      var pkg = ($(this).data("vuln-package") || "").toString().toLowerCase();
      var desc = ($(this).data("vuln-desc") || "").toString().toLowerCase();

      var sevMatch = state.filter === "all" || sev === state.filter;
      var queryMatch = state.query === "" || id.includes(state.query) || pkg.includes(state.query) || desc.includes(state.query);

      if (sevMatch && queryMatch) {
        filtered.push(this);
      }
    });

    allRows.addClass("hidden");
    $(filtered).removeClass("hidden");

    var total = filtered.length;
    var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    if (state.page > totalPages) state.page = totalPages;

    var start = (state.page - 1) * PAGE_SIZE;
    var end = Math.min(start + PAGE_SIZE, total);

    $(filtered).each(function (i) {
      if (i < start || i >= end) {
        $(this).addClass("hidden");
      }
    });

    noResults.toggle(total === 0);
    tableWrapper.toggle(total > 0);
    pagination.toggle(total > 0);

    pagination.find(".pagination-range").text(total === 0 ? "0-0" : (start + 1) + "-" + end);
    pagination.find(".pagination-total").text(total);
    pagination.find(".pagination-prev").prop("disabled", state.page <= 1);
    pagination.find(".pagination-next").prop("disabled", state.page >= totalPages);
    pagination.data("total-pages", totalPages);

    renderPageNumbers(pagination, state.page, totalPages);
  }

  function updateSbomView(manifestId, page, query) {
    var tableWrapper = $('[data-sbom-table="' + manifestId + '"]');
    var pagination = $('[data-sbom-pagination="' + manifestId + '"]');
    var noResults = $('[data-sbom-no-results="' + manifestId + '"]');

    var allRows = tableWrapper.find(".sbom-row");
    var filtered = [];

    allRows.each(function () {
      var pkg = ($(this).data("sbom-pkg") || "").toString();
      if (query === "" || pkg.includes(query)) {
        filtered.push(this);
      }
    });

    allRows.addClass("hidden");
    $(filtered).removeClass("hidden");

    var total = filtered.length;
    var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    if (page > totalPages) page = totalPages;

    var start = (page - 1) * PAGE_SIZE;
    var end = Math.min(start + PAGE_SIZE, total);

    $(filtered).each(function (i) {
      if (i < start || i >= end) {
        $(this).addClass("hidden");
      }
    });

    noResults.toggle(total === 0);
    tableWrapper.toggle(total > 0);
    pagination.toggle(total > 0);

    pagination.data("current-page", page);
    pagination.data("total-pages", totalPages);

    pagination.find(".pagination-range").text(total === 0 ? "0-0" : (start + 1) + "-" + end);
    pagination.find(".pagination-total").text(total);
    pagination.find(".pagination-prev").prop("disabled", page <= 1);
    pagination.find(".pagination-next").prop("disabled", page >= totalPages);

    renderPageNumbers(pagination, page, totalPages);
  }

  function renderPageNumbers(container, currentPage, totalPages) {
    var pagesEl = container.find(".pagination-pages");
    pagesEl.empty();

    if (totalPages <= 7) {
      for (var i = 1; i <= totalPages; i++) {
        pagesEl.append(createPageBtn(i, currentPage));
      }
    } else {
      pagesEl.append(createPageBtn(1, currentPage));
      if (currentPage > 3) pagesEl.append('<span class="pagination-ellipsis">…</span>');
      var s = Math.max(2, currentPage - 1);
      var e = Math.min(totalPages - 1, currentPage + 1);
      for (var j = s; j <= e; j++) {
        pagesEl.append(createPageBtn(j, currentPage));
      }
      if (currentPage < totalPages - 2) pagesEl.append('<span class="pagination-ellipsis">…</span>');
      pagesEl.append(createPageBtn(totalPages, currentPage));
    }
  }

  function createPageBtn(pageNum, currentPage) {
    var cls = "pagination-page";
    if (pageNum === currentPage) cls += " active";
    return '<button class="' + cls + '" data-page="' + pageNum + '">' + pageNum + '</button>';
  }

  // All event handlers bound once on document (delegation works for dynamic content)
  $(document)
    .off("click.vuln-filter").on("click.vuln-filter", "[data-vuln-filter]", function () {
      var manifestId = $(this).closest("[data-vuln-filter-chips]").data("vuln-filter-chips");
      var filter = $(this).data("vuln-filter");
      $(this).siblings().removeClass("active");
      $(this).addClass("active");
      var state = getVulnState(manifestId);
      state.filter = filter;
      state.page = 1;
      updateVulnView(manifestId, state);
    })
    .off("input.vuln-search").on("input.vuln-search", "[data-vuln-search]", function () {
      var manifestId = $(this).data("vuln-search");
      var state = getVulnState(manifestId);
      state.query = $(this).val().toLowerCase().trim();
      state.page = 1;
      updateVulnView(manifestId, state);
    })
    .off("click.vuln-page").on("click.vuln-page", "[data-vuln-pagination] .pagination-btn, [data-vuln-pagination] .pagination-page", function () {
      var manifestId = $(this).closest("[data-vuln-pagination]").data("vuln-pagination");
      var state = getVulnState(manifestId);
      var totalPages = $(this).closest("[data-vuln-pagination]").data("total-pages") || 1;

      if ($(this).hasClass("pagination-prev") && state.page > 1) {
        state.page--;
      } else if ($(this).hasClass("pagination-next") && state.page < totalPages) {
        state.page++;
      } else if ($(this).hasClass("pagination-page")) {
        state.page = parseInt($(this).data("page"));
      } else {
        return;
      }
      updateVulnView(manifestId, state);
    })
    .off("input.sbom-search").on("input.sbom-search", "[data-sbom-search]", function () {
      var manifestId = $(this).data("sbom-search");
      var query = $(this).val().toLowerCase().trim();
      updateSbomView(manifestId, 1, query);
    })
    .off("click.sbom-page").on("click.sbom-page", "[data-sbom-pagination] .pagination-btn, [data-sbom-pagination] .pagination-page", function () {
      var manifestId = $(this).closest("[data-sbom-pagination]").data("sbom-pagination");
      var query = ($(this).closest(".sbom-content").find("[data-sbom-search]").val() || "").toLowerCase().trim();
      var totalPages = $(this).closest("[data-sbom-pagination]").data("total-pages") || 1;
      var page = $(this).closest("[data-sbom-pagination]").data("current-page") || 1;

      if ($(this).hasClass("pagination-prev") && page > 1) {
        page--;
      } else if ($(this).hasClass("pagination-next") && page < totalPages) {
        page++;
      } else if ($(this).hasClass("pagination-page")) {
        page = parseInt($(this).data("page"));
      } else {
        return;
      }
      updateSbomView(manifestId, page, query);
    })
    .off("click.sort").on("click.sort", ".sortable-th", function () {
      var th = $(this);
      var table = th.closest("[data-sortable-table]");
      var sortType = th.data("sort-type");
      var colIndex = th.index();
      var tbody = table.find("tbody");

      saveOriginalOrder(table);

      var isDesc = th.hasClass("sorted-desc");
      var isAsc = th.hasClass("sorted-asc");

      if (isDesc) {
        var newDir = "asc";
        th.closest("thead").find(".sortable-th").removeClass("sorted-asc sorted-desc");
        th.addClass("sorted-asc");
      } else if (isAsc) {
        restoreOriginalOrder(table);
        applyDefaultSortIndicators(table);
        var isVuln = table.closest("[data-vuln-table]").length;
        var isSbom = table.closest("[data-sbom-table]").length;
        if (isVuln) {
          var manifestId = table.closest("[data-vuln-table]").data("vuln-table");
          var state = getVulnState(manifestId);
          state.page = 1;
          updateVulnView(manifestId, state);
        } else if (isSbom) {
          var sbomManifestId = table.closest("[data-sbom-table]").data("sbom-table");
          var query = ($('[data-sbom-search="' + sbomManifestId + '"]').val() || "").toLowerCase().trim();
          updateSbomView(sbomManifestId, 1, query);
        }
        return;
      } else {
        var newDir = "desc";
        th.closest("thead").find(".sortable-th").removeClass("sorted-asc sorted-desc");
        th.addClass("sorted-desc");
      }

      var rows = tbody.find("tr").get();

      rows.sort(function (a, b) {
        var aVal = $(a).find("td").eq(colIndex).data("sort-value");
        var bVal = $(b).find("td").eq(colIndex).data("sort-value");

        if (aVal == null) aVal = "";
        if (bVal == null) bVal = "";

        var cmp;

        if (sortType === "number") {
          cmp = (parseFloat(aVal) || 0) - (parseFloat(bVal) || 0);
        } else {
          cmp = String(aVal).localeCompare(String(bVal), "zh-CN");
        }

        return newDir === "asc" ? cmp : -cmp;
      });

      $.each(rows, function (i, row) {
        tbody.append(row);
      });

      if (table.closest("[data-vuln-table]").length) {
        var manifestId = table.closest("[data-vuln-table]").data("vuln-table");
        var state = getVulnState(manifestId);
        state.page = 1;
        updateVulnView(manifestId, state);
      } else if (table.closest("[data-sbom-table]").length) {
        var sbomManifestId = table.closest("[data-sbom-table]").data("sbom-table");
        var query = ($('[data-sbom-search="' + sbomManifestId + '"]').val() || "").toLowerCase().trim();
        updateSbomView(sbomManifestId, 1, query);
      }
    });

  initTableState(document);

  $(document).off("turbo:frame-load.table").on("turbo:frame-load.table", function (e) {
    initTableState(e.target);
  });
});

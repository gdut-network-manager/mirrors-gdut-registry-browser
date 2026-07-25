class Manifest
  include ActiveModel::Model

  attr_accessor(
    :architecture,
    :content_digest,
    :created,
    :env,
    :history,
    :labels,
    :layers,
    :size,
    :os,
    :scan_overview,
    :sbom_overview,
    :vulnerabilities
  )

  def id
    [ os, architecture ].join("-")
  end

  # scan_overview 是 MIME 类型为键的 Map, 取第一个值
  def scan_report
    return nil unless scan_overview.is_a?(Hash) && scan_overview.any?
    scan_overview.values.first
  end

  def scan_status
    scan_report&.dig("scan_status") || sbom_overview&.dig("scan_status")
  end

  def scan_severity
    scan_report&.dig("severity")
  end

  def scan_summary
    scan_report&.dig("summary")
  end

  def scan_scanner
    scan_report&.dig("scanner") || sbom_overview&.dig("scanner")
  end

  def scan_complete_percent
    scan_report&.dig("complete_percent")
  end

  def scan_duration
    scan_report&.dig("duration") || sbom_overview&.dig("duration")
  end

  def scan_start_time
    scan_report&.dig("start_time") || sbom_overview&.dig("start_time")
  end

  def scan_end_time
    scan_report&.dig("end_time") || sbom_overview&.dig("end_time")
  end

  VULN_SEVERITY_ORDER = %w[Critical High Medium Low Unknown].freeze

  def vuln_severity_counts
    return {} unless scan_summary && scan_summary["summary"]
    scan_summary["summary"]
  end

  def vuln_total
    scan_summary&.dig("total") || 0
  end

  def vuln_fixable
    scan_summary&.dig("fixable") || 0
  end

  # 按严重性分组的漏洞列表, 组内按 CVSS v3 降序
  def vuln_grouped
    return {} unless vulnerabilities.is_a?(Array) && vulnerabilities.any?
    vulnerabilities.group_by { |v| v["severity"] }
                   .sort_by { |sev, _| VULN_SEVERITY_ORDER.index(sev) || 99 }
                   .map do |sev, items|
                     sorted = items.sort_by do |v|
                       score = v.dig("preferred_cvss", "score_v3")
                       [ score.present? ? -score : Float::INFINITY ]
                     end
                     [ sev, sorted ]
                   end.to_h
  end

  def sbom_digest
    sbom_overview&.dig("sbom_digest")
  end

  def sbom_scan_status
    sbom_overview&.dig("scan_status")
  end
end

module ApplicationHelper
  def flash_css_class(type)
    {
      "notice" => "warning",
      "error"  => "danger"
    }.fetch(type, type)
  end

  def pull_command_prefix(project_name, repository_name, tag_name)
    base = Rails.configuration.x.public_registry_url
    return nil unless base

    domain = base.sub(/^https?:\/\//, "")
    "docker pull #{domain}/#{project_name}/#{repository_name}:#{tag_name}"
  end

  def pull_command_mirror(project_name, repository_name, tag_name)
    base = Rails.configuration.x.public_registry_url
    return nil unless base

    domain = base.sub(/^https?:\/\//, "")
    subdomain = domain_mirror_subdomain(project_name)
    return nil unless subdomain

    "docker pull #{subdomain}.#{domain}/#{repository_name}:#{tag_name}"
  end

  def domain_mirror_subdomain(project_name)
    map_string = Rails.configuration.x.domain_mirror_map
    return project_name unless map_string.present?

    map = map_string.split(",").each_with_object({}) do |entry, hash|
      key, value = entry.split(":")
      hash[key.strip] = value.strip if key && value
    end

    map[project_name] || project_name
  end

  def render_markdown(text)
    return "" unless text.present?
    Commonmarker.to_html(text, options: { render: { unsafe: true } }).html_safe
  end

  def bytes_to_human(bytes)
    return "0 B" if bytes.nil? || bytes.zero?
    units = ["B", "KB", "MB", "GB", "TB"]
    size = bytes.to_f
    unit = 0
    while size >= 1024 && unit < units.length - 1
      size /= 1024
      unit += 1
    end
    unit.zero? ? "#{size.to_i} #{units[unit]}" : "#{size.round(2)} #{units[unit]}"
  end

  VULN_SEVERITY_COLORS = {
    "Critical" => "#dc2626",
    "High"     => "#f97316",
    "Medium"   => "#f59e0b",
    "Low"      => "#3b82f6",
    "Unknown"  => "#94a3b8"
  }.freeze

  def vuln_severity_color(severity)
    VULN_SEVERITY_COLORS[severity] || "#94a3b8"
  end

  def vuln_severity_label(severity)
    {
      "Critical" => "危急",
      "High"     => "严重",
      "Medium"   => "中等",
      "Low"      => "较低",
      "Unknown"  => "无评分"
    }.fetch(severity, severity)
  end

  def vuln_severity_percent(count, total)
    return 0 if total.zero?
    (count.to_f / total * 100).round(2)
  end

  def format_cvss_score(score)
    return "—" if score.nil?
    score.to_s
  end

  def sbom_license_display(license)
    return "—" if license.blank? || license == "NOASSERTION"
    license
  end

  def sbom_version_display(version)
    return "—" if version.blank?
    version
  end

  def format_scan_status(status)
    {
      "Success"  => "已完成",
      "Running"  => "进行中",
      "Pending"  => "等待中",
      "Error"    => "失败",
      "NotScanned" => "未扫描"
    }.fetch(status, status)
  end
end

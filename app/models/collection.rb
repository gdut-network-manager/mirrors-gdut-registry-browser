class Collection
  include ActiveModel::Model
  include Enumerable

  attr_accessor :entries, :more, :total, :page

  delegate :each, to: :entries

  def last
    entries.last
  end

  def more?
    more
  end

  def total_pages
    return 1 if total.to_i.zero?
    page_size = Rails.configuration.x.page_size
    (total.to_f / page_size).ceil
  end
end

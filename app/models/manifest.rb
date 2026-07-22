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
    :os
  )

  def id
    [ os, architecture ].join("-")
  end
end

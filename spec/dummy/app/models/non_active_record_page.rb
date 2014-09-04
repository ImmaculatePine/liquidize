class NonActiveRecordPage
  include Liquidize::Model
  attr_accessor :body
  liquidize :body
end
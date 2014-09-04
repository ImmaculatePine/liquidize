class Page < ActiveRecord::Base
  include Liquidize::Model
  liquidize :body
end

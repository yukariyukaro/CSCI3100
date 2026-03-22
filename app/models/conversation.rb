class Conversation < ApplicationRecord
  belongs_to :item
  belongs_to :buyer
  belongs_to :seller
end

class Listing < ApplicationRecord
  belongs_to :user

  has_one :escrow, dependent: :destroy
  has_many :payments, through: :escrow

  enum :status, { available: 0, reserved: 1, sold: 2 }

  validates :title, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  def deposit_amount
    (price * BigDecimal("0.1")).round(2)
  end
end

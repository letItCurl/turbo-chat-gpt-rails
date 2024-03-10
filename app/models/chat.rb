class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  accepts_nested_attributes_for :messages
end

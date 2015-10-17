class Trend < ActiveRecord::Base
  has_and_belongs_to_many :tags

  validates :date, presence: true
  validates :date, uniqueness: true
end

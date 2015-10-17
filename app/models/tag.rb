class Tag < ActiveRecord::Base
  has_and_belongs_to_many :companies
  has_and_belongs_to_many :trends

  validates :name, :tag_type, presence: true
  validates :name, uniqueness: true
end

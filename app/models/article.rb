class Article < ActiveRecord::Base
  has_and_belongs_to_many :companies

  validates :title, :url, :source, :date, presence: true
  validates :url, uniqueness: true
end
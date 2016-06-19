class Company < ActiveRecord::Base
  has_many :apps_companies, :dependent => :destroy
  has_many :apps, :through => :apps_companies
  has_many :markers
  has_many :staffs
  belongs_to :character

  accepts_nested_attributes_for :apps_companies, :allow_destroy => true

  validates :name, presence: true
  validates :character_id, presence: true
  validates :enabled, presence: true
end

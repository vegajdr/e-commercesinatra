class Item < ActiveRecord::Base

has_many :purchases
has_many :users, through: :purchases
belongs_to :listed_by,
  class_name: "User"
end

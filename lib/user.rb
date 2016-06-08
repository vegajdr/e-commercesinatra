class User < ActiveRecord::Base

  def create_order item, amount
    purchases.create! item_id: item.id, quantity: amount.to_i

  end

  def add_item description, price
    items.create! description: description, price: price
  end

has_many :addresses
has_many :purchases
has_many :items, through: :purchases
end

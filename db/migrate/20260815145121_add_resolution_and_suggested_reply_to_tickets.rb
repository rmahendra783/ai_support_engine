class AddResolutionAndSuggestedReplyToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :resolution, :text
    add_column :tickets, :suggested_reply, :text
  end
end
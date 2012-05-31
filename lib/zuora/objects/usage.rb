module Zuora::Objects
  class Usage < Base
    belongs_to :account
    belongs_to :charge, :class_name => 'RatePlanCharge'
    belongs_to :subscription

    validates_presence_of :account_id, :unless => :account_number
    validates_length_of :account_number, :maximum => 255, :unless => :account_id

    validates_datetime_of :start_date_time, :allow_nil => true

    validates_numericality_of :quantity
    validates_presence_of :uom

    define_attributes do
      read_only :updated_by_id, :updated_date, :created_by_id, :created_date
    end
  end
end

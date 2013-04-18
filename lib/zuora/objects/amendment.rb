module Zuora::Objects
  class Amendment < Base
    belongs_to :subscription
    attr_accessor :product_rate_plan_id
    attr_accessor :rate_plan_id

    store_accessors :amend_options

    validates_presence_of :subscription_id, :name
    validates_length_of :name, :maximum => 100
    validates_inclusion_of :auto_renew, :in => [true, false], :allow_nil => true
    validates_length_of :code, :maximum => 50, :allow_nil => true
    validates_datetime_of :contract_effective_date, :allow_nil => true
    validates_datetime_of :customer_acceptance_date, :allow_nil => true
    validates_datetime_of :effective_date, :allow_nil => true
    validates_datetime_of :service_activation_date, :if => Proc.new { |a| a.status == 'PendingAcceptance' }
    validates_length_of :description, :maximum => 500, :allow_nil => true
    validates_numericality_of :initial_term, :if => Proc.new { |a| a.type == 'TermsAndConditions' }
    validates_numericality_of :renewal_term, :if => Proc.new { |a| a.type == 'TermsAndConditions' }
    validates_date_of :term_start_date, :if => Proc.new { |a| a.type == 'TermsAndConditions' }
    validates_presence_of :destination_account_id, :if => Proc.new {|a| a.type == 'OwnerTransfer' }
    validates_presence_of :destination_invoice_owner_id, :if => Proc.new {|a| a.type == 'OwnerTransfer' }
    validates_inclusion_of :status, :in => ["Completed", "Cancelled", "Draft", "Pending Acceptance", "Pending Activation"]
    validates_inclusion_of :term_type, :in => ['TERMED', 'EVERGREEN'], :allow_nil => true
    validates_inclusion_of :type, :in => ['Cancellation', 'NewProduct', 'OwnerTransfer', 'RemoveProduct', 'Renewal', 'UpdateProduct', 'TermsAndConditions']

    define_attributes do
      read_only :created_by_id, :created_date, :updated_by_id, :updated_date
      defaults :status => 'Draft'
    end

    def create
      return false unless valid?
      result = Zuora::Api.instance.request(:amend) do |xml|
        xml.__send__(zns, :requests) do |s|
          s.__send__(zns, :Amendments) do |a|
            to_hash.each do |k,v|
              a.__send__(ons, k.to_s.zuora_camelize.to_sym, v) unless v.nil?
            end
            a.__send__(zns, :RatePlanData) do |rpd|
              a.__send__(zns, :RatePlan) do |rp|
                rp.__send__(ons, :ProductRatePlanId, product_rate_plan_id) if product_rate_plan_id
                rp.__send__(ons, :AmendmentSubscriptionRatePlanId, rate_plan_id) if rate_plan_id
              end
            end
          end
          s.__send__(zns, :AmendOptions) do |ao|
            generate_amend_options(ao)
          end unless amend_options.blank?
        end
      end
      apply_create_response(result.to_hash, :amend_response)
    end

    def generate_rate_plan_data(builder)
      builder.__send__(ons, :ProductRatePlanId, product_rate_plan_id)
    end

    def generate_amend_options(builder)
      amend_options.each do |k,v|
        if v.is_a?(Hash)
          builder.__send__(zns, k.to_s.zuora_camelize.to_sym) do |subelem|
            v.each do |k1, v1|
              subelem.__send__(zns, k1.to_s.zuora_camelize.to_sym, v1)
            end
          end
        else
          builder.__send__(zns, k.to_s.zuora_camelize.to_sym, v)
        end
      end
    end

  protected

    def apply_create_response(response_hash, type)
      result = response_hash[type][:results]
      if result[:success]
        self.id = result[:amendment_ids]
        @previously_changed = changes
        @changed_attributes.clear
        return true
      else
        self.apply_errors(result)
        return false
      end
    end

  end
end

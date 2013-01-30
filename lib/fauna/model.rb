module Fauna
  class Model < Resource
    def self.inherited(base)
      base.send :extend, ActiveModel::Naming
      base.send :include, ActiveModel::Validations
      base.send :include, ActiveModel::Conversion

      # Callbacks support
      base.send :extend, ActiveModel::Callbacks
      base.send :include, ActiveModel::Validations::Callbacks
      base.send :define_model_callbacks, :save, :create, :update, :destroy

      # Serialization
      base.send :include, ActiveModel::Serialization
    end

    # TODO: use proper class here
    def self.find_by_id(id)
      ref =
        if self <= Fauna::User
          "users/#{id}"
        elsif self <= Fauna::User::Settings
          "users/#{id}/settings"
        else
          "instances/#{id}"
        end

      Fauna::Resource.find(ref)
    end

    def id
      ref.split("/").last
    end

    def save
      if valid?
        run_callbacks(:save) do
          if new_record?
            run_callbacks(:create) { super }
          else
            run_callbacks(:update) { super }
          end
        end
      else
        false
      end
    end

    def delete
      run_callbacks(:destroy) { super }
    end

    def valid?
      run_callbacks(:validate) { super }
    end

    def to_model
      self
    end
  end
end

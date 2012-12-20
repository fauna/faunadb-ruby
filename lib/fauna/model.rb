begin
  require 'active_model'
rescue LoadError => e
  $stderr.puts "You don't have activemodel installed. Please add it to use Fauna::Model."
  raise e
end

module Fauna
  class ResourceNotSaved < Exception
  end

  class ResourceNotFound < Exception
  end

  class Model
    def self.inherited(base)
      base.send :extend, ClassMethods
      base.send :extend, ActiveModel::Naming
      base.send :include, ActiveModel::Validations
      base.send :include, ActiveModel::Conversion
    end

    module ClassMethods
      attr_reader :ref

      def class_name
        model_name
      end

      def setup!
        resource = nil
        begin
          resource = Fauna::Class.find("classes/#{self.class_name}")['resource']
        rescue RestClient::ResourceNotFound
          resource = Fauna::Class.create(self.class_name)['resource']
        end
        @ref = resource['ref']
      end

      def create(attributes = {})
        self.new(attributes).tap do |res|
          res.save
        end
      end

      def create!(attributes = {})
        self.new(attributes).tap do |res|
          res.save!
        end
      end

      def find(ref)
        begin
          attributes = Fauna::Instance.find(ref)['resource']
          object = self.new(attributes.slice("ref", "ts", "data"))
          return object
        rescue RestClient::ResourceNotFound
          raise ResourceNotFound.new("Couldn't find resource with ref #{ref}")
        end
      end

      private

      def data_attr(*names)
        names.each do |attribute|
          attr = attribute.to_s
          define_method(attr) { @data[attr] }
          define_method("#{attr}=") { |value| @data[attr] = value }
        end
      end
    end

    attr_accessor :ref, :user, :data, :ts, :external_id, :references

    def initialize(params = {})
      @data = {}
      @ref = params.delete('ref') || params.delete(:ref)

      assign(params)
    end

    def id
      @id ||= (@ref ? @ref.split('/', 2)[1] : nil)
    end

    def save
      begin
        create_or_update
      rescue Exception
        false
      end
    end

    def save!
      create_or_update || raise(ResourceNotSaved)
    end

    def update(attributes)
      assign(attributes)
      save
    end

    def destroy
      Fauna::Instance.delete(@ref) if persisted?
      @ref = nil
      @destroyed = true
      freeze
    end

    def new_record?
      !@ref
    end

    def destroyed?
      !!(@destroyed ||= false)
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    private

    def create_or_update
      result = new_record? ? create_resource : update_resource
      !!result
    end

    def update_resource
      Fauna::Instance.update(ref, data)
      true
    end

    def create_resource
      response = Fauna::Instance.create(self.class.class_name,
                                        {'user' => user, 'data' => data})
      @ref = response["resource"]["ref"]
      true
    end

    def assign(attributes = {})
      attributes.each do |(attribute, value)|
        case attribute.to_s
        when 'user' then @user = value
        else @data[attribute.to_s] = value
        end
      end
    end
  end
end

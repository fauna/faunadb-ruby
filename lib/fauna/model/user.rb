require "fauna/model"

module Fauna
  class Model
    class User < Fauna::Model
      def self.inherited(base)
        super
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def ref
          "users"
        end

        def find(ref)
          begin
            ref = "users/#{ref}" unless ref =~ %r{users}
            attributes = Fauna::User.find(ref)['resource']
            object = self.new(attributes.slice("ref", "ts", "data", "references"))
            return object
          rescue RestClient::ResourceNotFound
            raise ResourceNotFound.new("Couldn't find resource with ref #{ref}")
          end
        end

        private
        def setup!
        end
      end

      attr_accessor :name, :email, :password

      def send_confirmation

      end

      def attributes
        { 'ref' => self.ref, 'data' => self.data, 'ts' => self.ts,
          'external_id' => self.external_id, 'references' => self.references }
      end

      def destroy
        run_callbacks :destroy do
          Fauna::User.delete(@ref) if persisted?
          @id = id
          @ref = nil
          @destroyed = true
        end
      end

      private
      def update_resource
        run_callbacks :update do
          Fauna::User.update(ref, { 'data' => data, 'references' => references })
        end
      end

      def create_resource
        run_callbacks :create do
          params = { 'name' => name, 'email' => email, 'password' => password,
                     'data' => data, 'references' => references }
          response = Fauna::User.create(params)
          attributes = response["resource"]
          @ref = attributes.delete("ref")
          data_attributes = attributes.delete("data") || {}
          assign(attributes.merge(data_attributes))
        end
      end
    end
  end
end

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
            raise ResourceNotFound.new("Couldn't find user with ref #{ref}")
          end
        end

        def find_by_email(email)
          begin
            response = Fauna::User.find("users?email=#{email}")
            # attributes = response['references'].first[1]
            attributes = response['resources'][0]
            attributes.select!{ |k, v| ["ref", "ts", "data", "references"].include?(k) }
            object = self.new(attributes)
            object.email = email
            return object
          rescue
            raise ResourceNotFound.new("Couldn't find user with email #{email}")
          end
        end

        private
        def setup!
        end
      end

      attr_accessor :name, :email, :password

      def authenticate(password)
        return false unless self.email
        begin
          data = self.class.connection.post("tokens", { :email => self.email, :password => password })
          response = self.class.parse_response(data)
          !!response["resource"]["token"]
        rescue
          false
        end
      end

      def send_confirmation_email
        self.class.connection.post("users/#{id}/settings/confirm_email", {})
        true
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

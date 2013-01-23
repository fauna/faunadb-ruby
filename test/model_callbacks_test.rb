require File.expand_path('../test_helper', __FILE__)

require "fauna/model"

class ModelCallbacksTest < MiniTest::Unit::TestCase
  stub_response(:put, fake_response(200, "OK", "class_model")) do
    class Henwen < Fauna::Model
      data_attr :used

      CALLBACKS = [
        :before_validation, :after_validation, :before_save, :around_save, :after_save,
        :before_create, :around_create, :after_create, :before_update, :around_update,
        :after_update, :before_destroy, :around_destroy, :after_destroy
      ]

      class << self
        def callback_string(callback_method)
          "history << [#{callback_method.to_sym.inspect}, :string]"
        end

        def callback_proc(callback_method)
          Proc.new { |model| model.history << [callback_method, :proc] }
        end

        def define_callback_method(callback_method)
          define_method(callback_method) do
            self.history << [callback_method, :method]
          end
          send(callback_method, :"#{callback_method}")
        end

        def callback_object(callback_method)
          klass = Class.new
          klass.send(:define_method, callback_method) do |model|
            model.history << [callback_method, :object]
          end
          klass.new
        end
      end

      CALLBACKS.each do |callback_method|
        next if callback_method.to_s =~ /^around_/
        define_callback_method(callback_method)
        send(callback_method, callback_string(callback_method))
        send(callback_method, callback_proc(callback_method))
        send(callback_method, callback_object(callback_method))
        send(callback_method) { |model| model.history << [callback_method, :block] }
      end

      def history
        @history ||= []
      end
    end
  end

  def test_create
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.create(:used => false)
      assert_equal [
        [:before_validation,            :method ],
        [:before_validation,            :string ],
        [:before_validation,            :proc   ],
        [:before_validation,            :object ],
        [:before_validation,            :block  ],
        [:after_validation,             :method ],
        [:after_validation,             :string ],
        [:after_validation,             :proc   ],
        [:after_validation,             :object ],
        [:after_validation,             :block  ],
        [ :before_save,                 :method ],
        [ :before_save,                 :string ],
        [ :before_save,                 :proc   ],
        [ :before_save,                 :object ],
        [ :before_save,                 :block  ],
        [ :before_create,               :method ],
        [ :before_create,               :string ],
        [ :before_create,               :proc   ],
        [ :before_create,               :object ],
        [ :before_create,               :block  ],
        [ :after_create,                :method ],
        [ :after_create,                :string ],
        [ :after_create,                :proc   ],
        [ :after_create,                :object ],
        [ :after_create,                :block  ],
        [ :after_save,                  :method ],
        [ :after_save,                  :string ],
        [ :after_save,                  :proc   ],
        [ :after_save,                  :object ],
        [ :after_save,                  :block  ]
      ], object.history
    end
  end

  def test_update
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.new(:used => false)
      object.save
      object.history.clear

      stub_response(:put, fake_response(200, "OK", "instance_used_model")) do
        object.update(:used => true)
        assert_equal [
          [:before_validation,            :method ],
          [:before_validation,            :string ],
          [:before_validation,            :proc   ],
          [:before_validation,            :object ],
          [:before_validation,            :block  ],
          [:after_validation,             :method ],
          [:after_validation,             :string ],
          [:after_validation,             :proc   ],
          [:after_validation,             :object ],
          [:after_validation,             :block  ],
          [ :before_save,                 :method ],
          [ :before_save,                 :string ],
          [ :before_save,                 :proc   ],
          [ :before_save,                 :object ],
          [ :before_save,                 :block  ],
          [ :before_update,               :method ],
          [ :before_update,               :string ],
          [ :before_update,               :proc   ],
          [ :before_update,               :object ],
          [ :before_update,               :block  ],
          [ :after_update,                :method ],
          [ :after_update,                :string ],
          [ :after_update,                :proc   ],
          [ :after_update,                :object ],
          [ :after_update,                :block  ],
          [ :after_save,                  :method ],
          [ :after_save,                  :string ],
          [ :after_save,                  :proc   ],
          [ :after_save,                  :object ],
          [ :after_save,                  :block  ]
        ], object.history
      end
    end
  end

  def test_destroy
    stub_response(:post, fake_response(201, "Created", "instance_model")) do
      object = Henwen.create(:used => false)
      object.history.clear

      stub_response(:delete, fake_response(204, "No Content", nil)) do
        object.destroy
        assert_equal [
          [ :before_destroy,              :method ],
          [ :before_destroy,              :string ],
          [ :before_destroy,              :proc   ],
          [ :before_destroy,              :object ],
          [ :before_destroy,              :block  ],
          [ :after_destroy,               :method ],
          [ :after_destroy,               :string ],
          [ :after_destroy,               :proc   ],
          [ :after_destroy,               :object ],
          [ :after_destroy,               :block  ]
        ], object.history
      end
    end
  end
end

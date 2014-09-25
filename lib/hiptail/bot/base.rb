require 'hiptail'
require 'rack'

module HipTail
  class Bot
    attr_reader :manager

    class << self
      def call(env)
        @rack_app ||= setup_rack_app()
        @rack_app.call(env)
      end

      private

      def setup_rack_app
        call_hook(:setup)

        config = (@rack_app_config || {}).dup
        config[:manager] ||= setup_manager()

        HipTail::Web::RackApp.new(config)
      end

      def setup_manager
        config = (@manager_config || {}).dup
        config[:authority_provider] ||= setup_authority_provider()

        manager = HipTail::Manager.new(config)
        setup_handlers(manager)
        manager
      end

      def setup_authority_provider
        call_hook(:authority_provider) || HipTail::MemoryAuthorityProvider.new()
      end

      def setup_handlers(manager)
        manager.on_install   { |authority| handle_installed(authority) }
        manager.on_uninstall { |oauth_id| handle_uninstalled(oauth_id) }
        manager.on_room_message      { |event| handle_message(event)      }
        manager.on_room_notification { |event| handle_notification(event) }
        manager.on_room_topic_change { |event| handle_topic(event)        }
        manager.on_room_enter        { |event| handle_room_enter(event)   }
        manager.on_room_exit         { |event| handle_room_exit(event)    }
      end

      def handle_installed(authority)
        call_hook(:on_installed, authority)
      end

      def handle_uninstalled(oauth_id)
        call_hook(:on_uninstalled, oauth_id)
      end

      def handle_message(event)
        message = event.message.text
        call_hook(:on_message, event) do |hook, *args|
          matcher, * = *hook[:args]
          case matcher
          when String
            next unless matcher == message
          when Regexp
            next unless matcher.match(message)
          end

          hook[:callback].call(*args)
        end
      end

      def handle_notification(event)
        message = event.message.text
        call_hook(:on_notification, event) do |hook, *args|
          matcher, * = *hook[:args]
          case matcher
          when String
            next unless matcher == message
          when Regexp
            next unless matcher.match(message)
          end

          hook[:callback].call(*args)
        end
      end

      def handle_topic(event)
        topic = event.topic
        call_hook(:on_topic, event) do |hook, *args|
          regex, * = *hook[:args]
          next if regex && ! regex.match(topic)

          hook[:callback].call(*args)
        end
      end

      def handle_room_enter(event)
        call_hook(:on_room_enter, event)
      end

      def handle_room_exit(event)
        call_hook(:on_room_exit, event)
      end
    end
  end

  module Bot::DSL
    def setup(&block)
      register_hook(:setup, &block)
    end

    def configure(config)
      @rack_app_config ||= {}
      @rack_app_config.merge! config
    end

    def configure_manager(config)
      @manager_config ||= {}
      @manager_config.merge! config
    end

    def authority_provider(&block)
      register_hook(:authority_provider, &block)
    end

    def on_message(*args, &block)
      register_hook(:on_message, *args, &block)
    end

    def on_notification(*args, &block)
      register_hook(:on_notification, *args, &block)
    end

    def register_hook(key, *args, &block)
      @hiptail_bot_hooks ||= {}
      @hiptail_bot_hooks[key] ||= []
      @hiptail_bot_hooks[key] << { :callback => block, :args => args }
    end

    def call_hook(key, *args)
      @hiptail_bot_hooks ||= {}
      return unless @hiptail_bot_hooks[key]

      res = nil
      @hiptail_bot_hooks[key].each do |hook|
        declined = false

        begin
          if block_given?
            res = yield hook, *args
          else
            res = hook[:callback].call(*args)
          end
        rescue LocalJumpError => e
          raise unless e.reason == :break
          declined = true
          res = e.exit_value
        end
        break if declined
      end

      res
    end
  end

  module Bot::Delegator
    class << self
      attr_accessor :target

      def delegate(*methods)
        methods.each do |method_name|
          define_method(method_name) do |*args, &block|
            return super(*args, &block) if respond_to? method_name
            Bot::Delegator.target.send(method_name, *args, &block)
          end
          private method_name
        end
      end
    end

    self.target = Bot

    delegate :setup, :configure, :configure_manager, :authority_provider
    delegate :on_installed, :on_uninstalled,
             :on_message, :on_notification, :on_topic,
             :on_room_enter, :on_room_exit
  end

  class Bot
    extend Bot::DSL
  end
end

require 'spree_api_v1'

module SpreeRelatedProducts
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_related_products'

    config.autoload_paths += %W(#{config.root}/lib)

    # Promotion rules need to be evaluated on after initialize otherwise
    # Spree.user_class would be nil and users might experience errors related
    # to malformed model associations (Spree.user_class is only defined on
    # the app initializer)
    config.after_initialize do
      config.spree.calculators.promotion_actions_create_adjustments << Spree::Calculator::RelatedProductDiscount
    end

    initializer "let the main autoloader ignore this engine's overrides" do
      if Rails.version >= "7.0"
        # Rails 7+ approach
        Rails.autoloaders.main.ignore(root.join("app/overrides"))
      else
        # Rails 6.1 approach
        ActiveSupport::Dependencies.autoload_paths -= [root.join("app/overrides")]
      end
    end

    class << self
      def activate
        cache_klasses = %W(#{config.root}/app/**/*_decorator*.rb)
        Dir.glob(cache_klasses) do |klass|
          Rails.configuration.cache_classes ? require(klass) : load(klass)
        end

        Dir.glob(File.join(File.dirname(__FILE__), "../../app/overrides/*.rb")) do |c|
          load(c)
        end
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end

require "handlebars"
require "active_support"

module ShtRails

  module Handlebars
    def self.has_partial?(name)
      if @context.present?
        current_partials = @context.instance_variable_get(:@partials).instance_variable_get(:@partials)
        return current_partials.key?(name)
      end

      false
    end

    def self.context(partials = nil)
      @context = nil unless ActionView::Resolver.caching?

      @context ||= begin
        context = ::Handlebars::Context.new

        if helpers = Rails.application.assets.find_asset(ShtRails.helper_path)
          context.runtime.eval helpers.source
        end

        context
      end

      partials.each do |k,v|
        @context.register_partial(k,v) unless has_partial?(k)
      end

      @context
    end

    def self.call(template)
      Rails.logger.info "------------------template: #{template}"
      if template.locals.include?(ShtRails.action_view_key.to_s) || template.locals.include?(ShtRails.action_view_key.to_sym)
<<-SHT
  hbs_context_for_sht = if defined?(partials) && partials.is_a?(Hash)
    ShtRails::Handlebars.context(partials)
  else
    ShtRails::Handlebars.context
  end
  hbs_context_for_sht.compile(#{template.source.inspect}).call(#{ShtRails.action_view_key.to_s} || {}).html_safe
SHT
      else
        "#{template.source.inspect}.html_safe"
      end
    end
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler(::ShtRails.template_extension.to_sym, ::ShtRails::Handlebars)
end
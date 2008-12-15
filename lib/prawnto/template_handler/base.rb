module Prawnto
  module TemplateHandler
    class Base < ActionView::TemplateHandler

      attr_reader :prawnto_options

      # Without overriding it, it does not work, do not know why.
      def initialize(view = nil)
        @view = view
      end

      # Hack for Rails 2.2. Having compilable templates with Prawn does not make sense.
      # so we shortcut the compilation stuff.
      def self.call(template)
        "#{name}.new(self).render(template, local_assigns)"
      end

      # TODO: kept around from railspdf-- maybe not needed anymore? should check.
      def ie_request?
        @view.request.env['HTTP_USER_AGENT'] =~ /msie/i
      end

      # TODO: kept around from railspdf-- maybe not needed anymore? should check.
      def set_pragma
        @view.headers['Pragma'] ||= ie_request? ? 'no-cache' : ''
      end

      # TODO: kept around from railspdf-- maybe not needed anymore? should check.
      def set_cache_control
        @view.headers['Cache-Control'] ||= ie_request? ? 'no-cache, must-revalidate' : ''
      end

      def set_content_type
        @view.response.content_type = Mime::PDF
      end

      def set_disposition
        inline = @prawnto_options[:inline] ? 'inline' : 'attachment'
        filename = @prawnto_options[:filename] ? "filename=#{@prawnto_options[:filename]}" : nil
        @view.headers["Content-Disposition"] = [inline,filename].compact.join(';')
      end

      def build_headers
        set_pragma
        set_cache_control
        set_content_type
        set_disposition
      end

      def pull_prawnto_options
        @prawnto_options = @view.controller.send :compute_prawnto_options
      end

      def render(template, local_assigns)
        pull_prawnto_options
        build_headers
        
        # store all the instance variables of the controller so that
        # we do not need the :dsl option anymore.
        variables = @view.controller.instance_variables.inject({}) do |h, v| 
          h.merge!(v => @view.controller.instance_variable_get(v))
        end

        (Prawn::Document.new(@prawnto_options[:prawn]) do
          # set the instance variables of the controller for the prawn template
          variables.each { |name, value| instance_variable_set name, value }
          eval template.source
        end).render
      end

    end
  end
end

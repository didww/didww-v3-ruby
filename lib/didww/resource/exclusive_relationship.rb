# frozen_string_literal: true
module DIDWW
  module Resource
    module ExclusiveRelationship
      class Relations < JsonApiClient::Relationships::Relations
        def initialize(record_class, relations, exclusions)
          @exclusions = exclusions
          @_initializing = true
          super(record_class, relations)
          @_initializing = false
        end

        def set_attribute(name, value)
          super
          return if @_initializing
          exclusive = @exclusions[name.to_s]
          if exclusive && !value.nil?
            super(exclusive, nil)
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def exclusive_relationships(mapping)
          full_mapping = {}
          mapping.each do |a, b|
            full_mapping[a.to_s] = b.to_s
            full_mapping[b.to_s] = a.to_s
          end
          full_mapping.freeze

          define_method(:_exclusive_relationship_mapping) { full_mapping }

          define_method(:relationships) do
            @relationships ||= Relations.new(self.class, {}, full_mapping)
          end

          define_method(:relationships=) do |rels|
            attrs = case rels
                    when JsonApiClient::Relationships::Relations then rels.attributes
                    when Hash then rels
                    else rels || {}
                    end
            @relationships = Relations.new(self.class, attrs, full_mapping)
          end
        end
      end
    end
  end
end

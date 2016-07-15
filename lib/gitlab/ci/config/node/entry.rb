module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Base abstract class for each configuration entry node.
        #
        class Entry
          class InvalidError < StandardError; end

          attr_reader :config, :attributes
          attr_accessor :key, :parent, :description

          def initialize(config, **metadata)
            @config = config
            @entries = {}
            @metadata = metadata

            @validator = self.class.validator.new(self)
            @validator.validate(:new)
          end

          def process!
            return unless valid?

            compose!
            @entries.each_value(&:process!)
          end

          def validate!
            return unless valid?

            @validator.validate(:processed)
            @entries.each_value(&:validate!)
          end

          def leaf?
            nodes.none?
          end

          def nodes
            self.class.nodes
          end

          def descendants
            @entries.values
          end

          def ancestors
            @parent ? @parent.ancestors + [@parent] : []
          end

          def valid?
            errors.none?
          end

          def errors
            @validator.messages + @entries.values.flat_map(&:errors)
          end

          def value
            if leaf?
              @config
            else
              meaningful = @entries.select do |_key, value|
                value.specified? && value.relevant?
              end

              Hash[meaningful.map { |key, entry| [key, entry.value] }]
            end
          end

          def specified?
            true
          end

          def relevant?
            true
          end

          def self.default
          end

          def self.nodes
            {}
          end

          def self.validator
            Validator
          end

          private

          def compose!
            nodes.each do |key, essence|
              @entries[key] = create(key, essence)
            end
          end

          def create(entry, essence)
            raise NotImplementedError
          end
        end
      end
    end
  end
end

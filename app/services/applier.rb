# frozen_string_literal: true

module Collude
  class Applier
    def initialize(changeset, collusion)
      @changeset = changeset
      @collusion = collusion
    end

    def apply!
      @changeset.changes.reduce('') do |value, change|
        range = range_from(change)

        if range
          value + @collusion.value[range]
        else
          value + change
        end
      end
    end

    private

    def range_from(change)
      Range.new(*change[2..-1].split('-').map(&:to_i)) if change[0..1] == 'øø'
    end
  end
end

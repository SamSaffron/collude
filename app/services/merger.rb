# frozen_string_literal: true

module Collude
  class Merger
    def initialize(changeset, collusion)
      @collusion = collusion
      @merging   = expand(changeset.changes)
      @existing  = expand(collusion.changeset.changes)
    end

    def merge!
      Changeset.new(
        length_before: @collusion.value.length,
        length_after: merged.length,
        changes: Array(merged)
      ).apply_to(@collusion)
    end

    private

    def expand(changes)
      changes.reduce([]) do |array, change|
        if change[0..1] == 'øø'
          array.concat Range.new(*change[2..-1].split('-').map(&:to_i)).to_a
        else
          array.concat change.split ''
        end
      end
    end

    def merged
      @merged ||= @collusion
                  .value
                  .each_char
                  .with_index
                  .reduce('') do |str, (change, index)|
        str += change if retain_character?(index)
        str += insertions_after(index)
        str
      end
    end

    def retain_character?(index)
      @merging.include?(index) && @existing.include?(index)
    end

    def insertions_after(index)
      [
        insertions_for(@merging, index),
        insertions_for(@existing, index)
      ].join
    end

    def insertions_for(changes, index)
      index = changes.index(index)
      return unless index

      ''.tap do |result|
        while changes[index + 1].is_a?(String)
          result << changes[index + 1]
          index += 1
        end
      end
    end
  end
end

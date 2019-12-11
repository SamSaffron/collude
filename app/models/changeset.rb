# frozen_string_literal: true

Changeset = Struct.new(
  :length_before,
  :length_after,
  :changes,
  keyword_init: true
) do
  def apply_to(collusion)
    if collusion.value.length != length_before
      Collude::Merger.new(self, collusion).merge!
    else
      Collude::Applier.new(self, collusion).apply!
    end
  end
end

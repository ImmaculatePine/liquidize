require 'spec_helper'

RSpec.describe Liquidize::Helper do
  describe '.recursive_stringify_keys' do
    let(:original) { { first: { a: 'a', b: 'b', c: 3}, second: :qwerty, third: [] } }
    let(:result) { { 'first' => { 'a' => 'a', 'b' => 'b', 'c' => 3}, 'second' => :qwerty, 'third' => [] } }

    it 'converts all keys to strings' do
      expect(Liquidize::Helper.recursive_stringify_keys(original)).to eq(result)
    end
  end
end
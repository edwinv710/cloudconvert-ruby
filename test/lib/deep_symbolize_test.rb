require 'test_helper'
require 'minitest/autorun'

describe "#deep_symbolize" do
   before :all do
      @regular_hash   = {'a' => 1, 'b' => 
         {'c' => 3, 'd' => 4}, 'e' => 
         [{'f' => 6, 'g' => 7}, {'h' => 8, 'i' => [
            {'j' => 9}, {'k' => 10}]}]}
      @symbolized_hash = {a: 1, b: {c: 3, d: 4}, e: [{f: 6, g: 7}, {h: 8, i: [{j: 9}, {k: 10}]}]}
   end

   it "should symbolize keys even if the values are hash or arrays" do
      @regular_hash.deep_symbolize.must_equal @symbolized_hash, @regular_hash.deep_symbolize == @symbolize_hash
   end
end
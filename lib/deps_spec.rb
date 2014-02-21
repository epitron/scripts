require 'minitest/autorun'
require_relative 'deps'

describe "deps" do

  it "bin_deps" do
    assert bin_deps("ls")
  end

  it "which" do
    assert which("ls")
  end
  
end
require 'minitest/autorun'
require_relative 'deps'

def exits_with_code(exitcode, &block)
  fork(&block)
  Process.wait
  assert_equal $?.exitstatus, exitcode
end

describe "deps" do

  it "bin_deps" do
    assert bin_deps("ls")

    capture_io do
      exits_with_code(1) { bin_deps("this_binary_does_not_exist") }
    end
  end

  it "which" do
    assert which("ls")
    assert !which("jasdfjaswerawerh")
  end

  it "dsls" do
    deps do
      bin "ls", arch: "binutils", deb: "", rpm: ""
      gem "blah"
    end
  end
  
end
load "../dm"


describe Line do

  it "should have a timestamp" do
    secs = 0.3324
    l = Line.new("blah", secs)
    l.secs.should == secs
  end
  

  it "should group repeats" do
    lines = %w[hello hello what amazing hello blah blah blah great amazing rle rle rle].map{|s| Line.new(s)}
    
    result = squash_repeats(lines)
    
    expected = [
      ["hello", 2],
      ["what", 1],
      ["amazing", 1],
      ["hello", 1],
      ["blah", 3],
      ["great", 1],
      ["amazing", 1],
      ["rle", 3],
    ]
    
    result.zip(expected).each do |line, (s, count)|
      line.should == s
      line.repeats.should == count
    end
  end
  
  it "should have a counter" do
    l = Line.new("I am a string.")
    
    l.repeats.should == 1
    l.repeats += 1
    l.repeats.should == 2
    
    l.merge(l)
    l.repeats.should == 4
  end

end


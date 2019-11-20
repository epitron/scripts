load "#{__dir__}/../wict"

def with_time(&block)
  start = Time.now
  result = block.call

  [result, Time.now-start].reverse
end

ensure_database!

# stats

q = %w[cliché]

results = {
  bsearch: with_time { lookup_bsearch(q) },
  grep:    with_time { lookup_grep(q) },
  look:    with_time { lookup_look(q) },
}

pp results
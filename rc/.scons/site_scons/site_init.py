import multiprocessing
SetOption('num_jobs', multiprocessing.cpu_count())
print "running with -j", GetOption('num_jobs')

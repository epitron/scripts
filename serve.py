#!/usr/bin/python2

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
import os
from pprint import pprint

PORT_NUMBER = 8080
MIMETYPES = {
	".html": 'text/html',
	".jpg":  'image/jpg',
	".gif":  'image/gif',
	".js":   'application/javascript',
	".css":  'text/css',
}


def ext(s):
	try:
		return s[s.rindex("."):]
	except ValueError:
		return None

class myHandler(BaseHTTPRequestHandler):
	
	def do_GET(self):
		
		mimetype = MIMETYPES.get(ext(self.path), "text/html")
		
		if self.path=="/":
			body = []
			for filename in os.listdir("."):
				body.append("<a href='%(filename)s'>%(filename)s</a><br>" % locals())
			body = ''.join(body) 
		else:
			try:
				with open(os.curdir + os.sep + self.path).read() as f:
					body = f.read()

			except IOError:
				self.send_error(404, 'File Not Found: %s' % self.path)
				return

		#import IPython;IPython.embed()
		ch, cp = self.client_address
		print
		print "======= %s:%d => %s" % (ch, cp, self.requestline)
		pprint(self.headers.dict)
		print

		self.send_response(200)

		self.send_header('Content-type', mimetype)
		self.end_headers()

		print len(body), "bytes sent"
		self.wfile.write(body)

try:
	server = HTTPServer(('', PORT_NUMBER), myHandler)
	print 'Started httpserver on port', PORT_NUMBER
	server.serve_forever()
except KeyboardInterrupt:
	print '^C received, shutting down the web server'
	server.socket.close()


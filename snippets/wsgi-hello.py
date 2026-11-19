# python -m pip install trustme
# python -m trustme -i example.com
# gunicorn --bind 127.0.0.1:3333 --certfile server.pem --keyfile server.key wsgi-hello:app
# curl --cacert client.pem --resolve example.com:3333:127.0.0.1 https://example.com:3333

def app(environ, start_fn):
    start_fn('200 OK', [('Content-Type', 'text/plain')])
    return [b"Hello World!\n"]

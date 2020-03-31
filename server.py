from subprocess import check_output, CalledProcessError
from http.server import HTTPServer, BaseHTTPRequestHandler

port = 8080
script_path = './mongo-backups.sh' 

class BashScriptHTTPRequestHandler(BaseHTTPRequestHandler):
  def do_GET(self):
    response = b''
    try:
      if self.path != '/':
        self.send_response(404)
      else:
        response = check_output(script_path)
        self.send_response(200)
    except CalledProcessError as error:
      response = b"-----------------------------\n"
      response += b"Error during script execution\n"
      response += b"-----------------------------\n\n"
      response += error.output
      self.send_response(500)
    finally:
      self.send_header("Content-type", "text/plain")
      self.end_headers()
      self.wfile.write(response)

httpd = HTTPServer(('0.0.0.0', port), BashScriptHTTPRequestHandler)
print("Serving at port", port)
httpd.serve_forever()

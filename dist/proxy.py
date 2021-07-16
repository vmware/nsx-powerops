#!/usr/local/opt/python@3.8/bin/python3.8
# coding: utf-8
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging, requests, base64, json, urllib3, json
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class S(BaseHTTPRequestHandler):
    def _set_response(self, response_code):
        self.send_response(int(response_code))
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'nsx, access-control-allow-headers,access-control-allow-methods,access-control-allow-origin,content-type, authorization')
        self.send_header('Access-Control-Allow-Methods', 'OPTIONS, HEAD, GET, POST, PUT, DELETE')
        self.end_headers()
        logging.info("Response Headers,\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))


    def do_OPTIONS(self):
        logging.info("OPTIONS request,\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))
        self._set_response('200')

    def do_GET(self):
        logging.info("GET request from Angular,\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))
        #get NSx Address
        nsx = self.headers.get('NSX')
        # get Authorization for credentials
        credentials = self.headers.get('Authorization').split(' ')[1]
        credentials = base64.b64decode(credentials)
        credentials = credentials.decode('ascii')
        tab_credentials = credentials.split(':')
        try:
            resp = requests.get('https://' + nsx + str(self.path), auth=(tab_credentials[0], tab_credentials[1]), verify=False)
            print(resp)
            # Respond with the requested data
            self._set_response(resp.status_code)
            self.wfile.write(resp.content)
        except requests.exceptions.RequestException as e:
            self._set_response(404)
            print('\n!!!> Error: %s' %e)

    def do_POST(self):
        content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
        post_data = self.rfile.read(content_length) # <--- Gets the data itself
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\n", str(self.path), str(self.headers))
        body = post_data.decode('utf-8')
        nsx = self.headers.get('NSX')
        if '&' in body:
            list_auth = body.split('&')
            username = list_auth[0].split('=')[1]
            password = list_auth[1].split('=')[1]
            body = {
                'j_username': username,
                'j_password': password
            }
            try:
                resp = requests.post('https://' + nsx + str(self.path), data=body, verify=False)
                print('> Response: %s' % resp)
                # Respond with the requested data
                self._set_response(resp.status_code)
                self.wfile.write(resp.content)
            except requests.exceptions.RequestException as e:
                self._set_response(401)
                print('\n!!!> Error: %s' %e)

        else:
            # get Authorization for credentials
            credentials = self.headers.get('Authorization').split(' ')[1]
            credentials = base64.b64decode(credentials)
            credentials = credentials.decode('ascii')
            tab_credentials = credentials.split(':')
            test = json.loads(body)
            try:
                resp = requests.post('https://' + nsx + str(self.path), auth=(tab_credentials[0], tab_credentials[1]), json=test, verify=False)
                print('> Response: %s' % resp)
                # Respond with the requested data
                self._set_response(resp.status_code)
                self.wfile.write(resp.content)
            except requests.exceptions.RequestException as e:
                self._set_response(401)
                print('\n!!!> Error: %s' %e)

        

def run(server_class=HTTPServer, handler_class=S, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    
    logging.info('Starting proxy httpd - port %s...\n' %port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping proxy httpd  ...\n')

if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
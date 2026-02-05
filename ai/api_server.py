#!/usr/bin/env python3
import json,os,sys,sqlite3
from http.server import BaseHTTPRequestHandler,HTTPServer
BASE_DIR=os.environ.get('BASE_DIR', "/home/loop/_/ai")
DB=os.path.join(BASE_DIR,'.db','ai_memory.db')
FIFO=os.path.join(BASE_DIR,'nexus.pipe')
WWW=os.path.join(BASE_DIR,'www')
class Handler(BaseHTTPRequestHandler):
    def _send(self,status,body):
        self.send_response(status)
        self.send_header('Content-Type','application/json')
        self.send_header('Content-Length',str(len(body.encode())))
        self.end_headers()
        self.wfile.write(body.encode())
    def do_GET(self):
        if self.path.startswith('/memory'):
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            rows=list(cur.execute('SELECT id,user,role,content,ts FROM memory ORDER BY id DESC LIMIT 50'))
            self._send(200,json.dumps(rows))
        elif self.path.startswith('/agent_output'):
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            rows=list(cur.execute('SELECT id,agent,model,substr(content,1,400) as content,ts FROM agent_output ORDER BY id DESC LIMIT 100'))
            self._send(200,json.dumps(rows))
        elif self.path == '/' or self.path.startswith('/index'):
            try:
                with open(os.path.join(WWW,'index.html'),'r',encoding='utf-8') as f:
                    data=f.read()
                self.send_response(200)
                self.send_header('Content-Type','text/html; charset=utf-8')
                self.end_headers()
                self.wfile.write(data.encode())
            except Exception as e:
                self._send(500,json.dumps({'error':str(e)}))
        else:
            self._send(404,json.dumps({'error':'not_found'}))
    def do_POST(self):
        length=int(self.headers.get('Content-Length','0'))
        raw=self.rfile.read(length).decode()
        try:
            data=json.loads(raw) if raw else {}
        except:
            data={}
        if self.path.startswith('/remember'):
            role=data.get('role','remote')
            content=data.get('content','')
            conn=sqlite3.connect(DB)
            cur=conn.cursor()
            cur.execute('INSERT INTO memory (user,role,content) VALUES (?,?,?)',('remote',role,content))
            conn.commit()
            self._send(200,json.dumps({'status':'remembered'}))
        elif self.path.startswith('/prompt'):
            prompt=data.get('prompt','')
            try:
                with open(FIFO,'w') as f:
                    f.write(prompt+'\n')
                self._send(200,json.dumps({'status':'accepted'}))
            except Exception as e:
                self._send(500,json.dumps({'error':str(e)}))
        else:
            self._send(404,json.dumps({'error':'not_found'}))
if __name__=='__main__':
    port=int(os.environ.get('API_PORT', "7331"))
    server=HTTPServer(('127.0.0.1',port),Handler)
    print('API server listening on http://127.0.0.1:%d' % port, file=sys.stderr)
    server.serve_forever()

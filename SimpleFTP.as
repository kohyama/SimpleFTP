package  {
  import flash.net.Socket;
  import flash.events.*;
  import flash.utils.getTimer;

  public class SimpleFTP {
    public static function putFile(host:String, user:String, pass:String, 
                                   path:String, contents:String,
                                   listener:Function) {
      var s:SimpleFTP = new SimpleFTP(host, user, pass);
      s.putFile(path, contents, listener);
    }

    public static function getFile(host:String, user:String, pass:String,
                                   path:String, listener:Function) {
      var s:SimpleFTP = new SimpleFTP(host, user, pass);
      s.getFile(path, listener);
    }

    private var host:String,user:String,pass:String;
    private var ctrlSocket:Socket = new Socket();
    private var dataSocket:Socket = new Socket();
    private var dataIP:String;
    private var dataPort:int;
    private var path:String, contents:String;
    private var listener:Function = null;
    private var step:int;
    private var put:Boolean;
    private var sa:Array;

    public function SimpleFTP(host:String, user:String, pass:String) {
      this.host = host;
      this.user = user;
      this.pass = pass;
      ctrlSocket.addEventListener(IOErrorEvent.IO_ERROR, error);
      ctrlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, error);
    }

    private function putFile(path:String, contents:String,
                             listener:Function):void {
      this.path = path;
      this.contents = contents;
      this.listener = listener;
      step = 0;
      put = true;
      ctrlSocket.addEventListener(ProgressEvent.SOCKET_DATA, session);
      ctrlSocket.connect(host, 21);
    }

    private function getFile(path:String, listener:Function):void {
      this.path = path;
      this.contents = contents;
      this.listener = listener;
      step = 0;
      put = false;
      ctrlSocket.addEventListener(ProgressEvent.SOCKET_DATA, session);
      ctrlSocket.connect(host, 21);
    }

    private function write(mes:String):void {
      ctrlSocket.writeUTFBytes(mes + "\r\n");
      ctrlSocket.flush();
    }
    
    private function response(res:String, contents:String = null):void {
      step = 11;
      if (put)
        listener(res);
      else
        listener(res, contents);
      write("QUIT");
    }
    
    private function error(event:Event):void {
      if (put)
        listener(event.toString());
      else
        listener(event.toString(), null);
    }

    private function session(event:ProgressEvent):void {
      var res:String = ctrlSocket.readUTFBytes(ctrlSocket.bytesAvailable);
      var st:String = res.substr(0, 3);
      trace(res);

      switch (step) {
      case 0:
        if (st == "220") {
          step++;
          write("USER " + user);
        } else
          response(res);
        break;
      case 1:
        if (st == "331") {
          step++;
          write("PASS " + pass);
        } else
          response(res);
        break;
      case 2:
        if (st == "230") {
          if (put)
            step = 3;
          else
            step = 4;
          write("TYPE I");
        } else
          response(res);
        break;
      case 3:
        if (st == "200") {
          write("DELE " + path);
          step++;
        } else
          response(res);
        break;
      case 4:
        write("PASV");
        if (put)
          step = 5;
        else
          step = 8;
        break;
      case 5:
        if (st == "227") {
          step++;
          sa = res.substring(res.indexOf("(") + 1, res.indexOf(")")).split(",");
          dataIP = sa[0] + "." + sa[1] + "." + sa[2] + "." + sa[3];
          dataPort = parseInt(sa[4]) * 256 + parseInt(sa[5]);
          write("STOR " + path);
          dataSocket.connect(dataIP, dataPort);
        } else
          response(res);
        break;
      case 6:
        if (st == "125") {
          step++;
          dataSocket.writeUTFBytes(contents);
          dataSocket.flush();
          dataSocket.close();
        } else {
          dataSocket.close();
          response(res);
        }
        break;
      case 7:
        response(res); // regardless if the res is "226" or not.
        break;
      case 8:
        if (st == "227") {
          step++;
          sa = res.substring(res.indexOf("(") + 1, res.indexOf(")")).split(",");
                  dataIP = sa[0] + "." + sa[1] + "." + sa[2] + "." + sa[3];
                  dataPort = parseInt(sa[4]) * 256 + parseInt(sa[5]);
          contents = "";
          dataSocket.addEventListener(ProgressEvent.SOCKET_DATA,
            function (event:ProgressEvent):void {
              contents += dataSocket.readUTFBytes(dataSocket.bytesAvailable);
            });
          dataSocket.connect(dataIP, dataPort);
          write("RETR " + path);
        } else
          response(res);
        break;
      case 9:
        if (st == "125")
          step++;
        else {
          dataSocket.close();
          response(res);
        }
        break;
      case 10:
        if (st == "226") // succeeded
          response(res, contents);
        else
          response(res);
        break;
      case 11:
        break;
      }
    }
  } 
}
